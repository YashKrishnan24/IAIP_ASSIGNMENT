// ============================================================
//  employees.js — Employee list page logic
// ============================================================

// ─── State ───────────────────────────────────────────────────────────────────
let empState = {
  employees:  [],
  departments:[],
  roles:      [],
  totalCount: 0,
  pageNumber: 1,
  pageSize:   10,
  sortBy:     'EmployeeCode',
  sortDir:    'ASC',
  filters: {
    search: '', departmentId: '', roleId: '', status: '',
    gender: '', joiningDateFrom: '', joiningDateTo: '',
    minSalary: '', maxSalary: '', salaryRange: '',
  },
  editingId:    null,
  transferring: null,
};

// ─── Init ─────────────────────────────────────────────────────────────────────
async function initEmployeePage() {
  Auth.requireAuth();
  renderSidebarUser();
  setActiveNav('employees');

  // Load lookups
  await Promise.all([loadDepartments(), loadRoles()]);
  populateDeptFilters();
  populateRoleFilters();
  populateDeptFormOptions();
  populateRoleFormOptions();
  populateSalaryRanges();

  // Wire events
  wireFilterEvents();
  wireTableSort();
  wireFormEvents();
  wireTransferEvents();

  // Manage role visibility
  if (!Auth.isManager()) {
    qsa('.manager-only').forEach(el => el.classList.add('hidden'));
  }

  // Load first page
  await loadEmployees();
}

// ─── Load employees ───────────────────────────────────────────────────────────
async function loadEmployees() {
  showTableLoading(true);
  try {
    const params = buildParams();
    const res = await EmployeeApi.getAll(params);
    empState.employees  = res.data.data;
    empState.totalCount = res.data.totalCount;
    empState.pageNumber = res.data.pageNumber;
    empState.pageSize   = res.data.pageSize;
    renderTable();
    renderPagination();
    updateStats();
  } catch (err) {
    Toast.error('Load failed', err.message);
  } finally {
    showTableLoading(false);
  }
}

function buildParams() {
  const f = empState.filters;
  const params = {
    pageNumber:     empState.pageNumber,
    pageSize:       empState.pageSize,
    sortBy:         empState.sortBy,
    sortDirection:  empState.sortDir,
  };
  if (f.search)         params.search         = f.search;
  if (f.departmentId)   params.departmentId   = f.departmentId;
  if (f.roleId)         params.roleId         = f.roleId;
  if (f.status)         params.status         = f.status;
  if (f.gender)         params.gender         = f.gender;
  if (f.joiningDateFrom) params.joiningDateFrom = f.joiningDateFrom;
  if (f.joiningDateTo)   params.joiningDateTo   = f.joiningDateTo;
  if (f.minSalary)      params.minSalary      = f.minSalary;
  if (f.maxSalary)      params.maxSalary      = f.maxSalary;
  return params;
}

// ─── Table Render ─────────────────────────────────────────────────────────────
function renderTable() {
  const tbody = document.getElementById('emp-tbody');
  if (!tbody) return;

  if (empState.employees.length === 0) {
    tbody.innerHTML = `
      <tr><td colspan="10">
        <div class="empty-state">
          <div class="empty-icon">🔍</div>
          <h3>No employees found</h3>
          <p>Try adjusting your search or filters.</p>
        </div>
      </td></tr>`;
    return;
  }

  tbody.innerHTML = empState.employees.map(e => `
    <tr>
      <td>
        <span class="emp-code-link" onclick="viewEmployee(${e.employeeId})">${e.employeeCode}</span>
      </td>
      <td>
        <div class="d-flex align-center gap-3">
          <div class="user-avatar" style="width:32px;height:32px;font-size:.7rem">${getInitials(e.fullName)}</div>
          <span class="fw-600">${e.fullName}</span>
        </div>
      </td>
      <td><span class="text-sm">${e.departmentName}</span></td>
      <td><span class="text-sm">${e.roleName}</span></td>
      <td><span class="text-sm text-muted">${e.email}</span></td>
      <td><span class="text-sm">${e.mobileNumber}</span></td>
      <td><span class="salary-display">${formatCurrency(e.annualSalary)}</span></td>
      <td>
        <span class="badge badge-${e.employeeStatus.toLowerCase()}">
          <span class="badge-dot"></span>${e.employeeStatus}
        </span>
      </td>
      <td>
        <div class="action-group">
          <button class="action-btn view"     onclick="viewEmployee(${e.employeeId})"     title="View Details">👁</button>
          ${Auth.isManager() ? `
          <button class="action-btn edit"     onclick="editEmployee(${e.employeeId})"    title="Edit Employee">✏️</button>
          <button class="action-btn transfer" onclick="openTransfer(${e.employeeId})"    title="Transfer Department">🔄</button>` : ''}
          ${Auth.isAdmin() ? `
          <button class="action-btn delete"   onclick="deactivateEmployee(${e.employeeId}, '${e.fullName}')" title="Deactivate">🗑</button>` : ''}
        </div>
      </td>
    </tr>`).join('');
}

// ─── Pagination Render ────────────────────────────────────────────────────────
function renderPagination() {
  const totalPages = Math.ceil(empState.totalCount / empState.pageSize);
  const from = (empState.pageNumber - 1) * empState.pageSize + 1;
  const to   = Math.min(empState.pageNumber * empState.pageSize, empState.totalCount);

  const info = document.getElementById('pagination-info');
  if (info) info.textContent = empState.totalCount > 0
    ? `Showing ${from}–${to} of ${empState.totalCount} employees`
    : 'No results';

  const ctrl = document.getElementById('pagination-controls');
  if (!ctrl) return;

  const pages = [];
  const curr  = empState.pageNumber;

  pages.push(1);
  if (curr > 3) pages.push('...');
  for (let p = Math.max(2, curr - 1); p <= Math.min(totalPages - 1, curr + 1); p++) pages.push(p);
  if (curr < totalPages - 2) pages.push('...');
  if (totalPages > 1) pages.push(totalPages);

  ctrl.innerHTML = `
    <button class="page-btn" ${curr === 1 ? 'disabled' : ''} onclick="changePage(${curr - 1})">‹</button>
    ${pages.map(p => p === '...'
      ? `<span class="text-muted" style="padding:0 4px">…</span>`
      : `<button class="page-btn ${p === curr ? 'active' : ''}" onclick="changePage(${p})">${p}</button>`
    ).join('')}
    <button class="page-btn" ${curr === totalPages ? 'disabled' : ''} onclick="changePage(${curr + 1})">›</button>
    <select class="page-size-select" onchange="changePageSize(this.value)">
      ${CONFIG.PAGE_SIZES.map(s => `<option ${s === empState.pageSize ? 'selected' : ''} value="${s}">${s} / page</option>`).join('')}
    </select>`;
}

function changePage(page) {
  const totalPages = Math.ceil(empState.totalCount / empState.pageSize);
  if (page < 1 || page > totalPages) return;
  empState.pageNumber = page;
  loadEmployees();
}

function changePageSize(size) {
  empState.pageSize   = parseInt(size);
  empState.pageNumber = 1;
  loadEmployees();
}

// ─── Sort ─────────────────────────────────────────────────────────────────────
function wireTableSort() {
  qsa('thead th.sortable').forEach(th => {
    th.addEventListener('click', () => {
      const col = th.dataset.col;
      if (empState.sortBy === col) {
        empState.sortDir = empState.sortDir === 'ASC' ? 'DESC' : 'ASC';
      } else {
        empState.sortBy  = col;
        empState.sortDir = 'ASC';
      }
      qsa('thead th.sortable').forEach(h => {
        h.classList.remove('sort-asc', 'sort-desc');
        h.querySelector('.sort-icon').textContent = '⇅';
      });
      th.classList.add(`sort-${empState.sortDir.toLowerCase()}`);
      th.querySelector('.sort-icon').textContent = empState.sortDir === 'ASC' ? '↑' : '↓';
      empState.pageNumber = 1;
      loadEmployees();
    });
  });
}

// ─── Filters & Search ─────────────────────────────────────────────────────────
function wireFilterEvents() {
  const debSearch = debounce(val => {
    empState.filters.search = val;
    empState.pageNumber = 1;
    loadEmployees();
  }, 400);

  const gs = document.getElementById('global-search');
  if (gs) gs.addEventListener('input', e => debSearch(e.target.value));

  const topSearch = document.getElementById('topbar-search-input');
  if (topSearch) topSearch.addEventListener('input', e => debSearch(e.target.value));

  // Filter dropdowns
  const bindFilter = (id, key) => {
    const el = document.getElementById(id);
    if (el) el.addEventListener('change', e => {
      empState.filters[key] = e.target.value;
      empState.pageNumber   = 1;
      loadEmployees();
    });
  };

  bindFilter('filter-dept',   'departmentId');
  bindFilter('filter-role',   'roleId');
  bindFilter('filter-status', 'status');
  bindFilter('filter-gender', 'gender');

  // Joining date range
  const jFrom = document.getElementById('filter-joining-from');
  const jTo   = document.getElementById('filter-joining-to');
  if (jFrom) jFrom.addEventListener('change', e => { empState.filters.joiningDateFrom = e.target.value; empState.pageNumber = 1; loadEmployees(); });
  if (jTo)   jTo.addEventListener('change',   e => { empState.filters.joiningDateTo   = e.target.value; empState.pageNumber = 1; loadEmployees(); });

  // Salary range preset
  const salaryPreset = document.getElementById('filter-salary-range');
  const customMin    = document.getElementById('filter-custom-min');
  const customMax    = document.getElementById('filter-custom-max');
  const customRow    = document.getElementById('custom-salary-row');

  if (salaryPreset) salaryPreset.addEventListener('change', e => {
    const idx  = parseInt(e.target.value);
    const range = CONFIG.SALARY_RANGES[idx];
    if (!range) return;
    if (range.min === 'custom') {
      if (customRow) customRow.classList.remove('hidden');
      return;
    }
    if (customRow) customRow.classList.add('hidden');
    empState.filters.minSalary = range.min ?? '';
    empState.filters.maxSalary = range.max ?? '';
    empState.pageNumber = 1;
    loadEmployees();
  });

  const applyCustomSalary = debounce(() => {
    empState.filters.minSalary = customMin?.value || '';
    empState.filters.maxSalary = customMax?.value || '';
    empState.pageNumber = 1;
    loadEmployees();
  }, 600);

  if (customMin) customMin.addEventListener('input', applyCustomSalary);
  if (customMax) customMax.addEventListener('input', applyCustomSalary);

  // Reset
  const resetBtn = document.getElementById('btn-reset-filters');
  if (resetBtn) resetBtn.addEventListener('click', resetFilters);
}

function resetFilters() {
  empState.filters    = { search: '', departmentId: '', roleId: '', status: '', gender: '', joiningDateFrom: '', joiningDateTo: '', minSalary: '', maxSalary: '', salaryRange: '' };
  empState.pageNumber = 1;
  empState.pageSize   = 10;
  qsa('#filter-dept, #filter-role, #filter-status, #filter-gender, #filter-salary-range').forEach(el => el && (el.value = ''));
  const customRow = document.getElementById('custom-salary-row');
  if (customRow) customRow.classList.add('hidden');
  qsa('#filter-joining-from, #filter-joining-to, #filter-custom-min, #filter-custom-max').forEach(el => el && (el.value = ''));
  const gs = document.getElementById('global-search');
  if (gs) gs.value = '';
  loadEmployees();
}

// ─── View Employee Detail ─────────────────────────────────────────────────────
async function viewEmployee(id) {
  openModal('detail-modal');
  const body = document.getElementById('detail-body');
  body.innerHTML = '<div class="empty-state"><div class="spinner"></div></div>';
  try {
    const res = await EmployeeApi.getById(id);
    const e   = res.data;
    body.innerHTML = `
      <div class="detail-header">
        <div class="detail-avatar">${getInitials(e.fullName)}</div>
        <div class="detail-meta">
          <div class="detail-emp-name">${e.fullName}</div>
          <div class="detail-emp-code">${e.employeeCode}</div>
          <div class="detail-emp-role">${e.roleName} · ${e.departmentName}</div>
          <div class="mt-4">
            <span class="badge badge-${e.employeeStatus.toLowerCase()}">
              <span class="badge-dot"></span>${e.employeeStatus}
            </span>
          </div>
        </div>
      </div>
      <div class="modal-body">
        <div class="detail-grid">
          <div class="form-section-title" style="grid-column:1/-1">📋 Employment Details</div>
          ${detailField('Department', e.departmentName)}
          ${detailField('Role / Designation', e.roleName)}
          ${detailField('Joining Date', formatDate(e.joiningDate))}
          ${detailField('Annual Salary', formatCurrency(e.annualSalary))}
          ${detailField('Employee Status', `<span class="badge badge-${e.employeeStatus.toLowerCase()}"><span class="badge-dot"></span>${e.employeeStatus}</span>`)}

          <div class="form-section-title" style="grid-column:1/-1">👤 Personal Information</div>
          ${detailField('Email', `<a href="mailto:${e.email}">${e.email}</a>`)}
          ${detailField('Mobile', e.mobileNumber)}
          ${detailField('Gender', e.gender)}
          ${detailField('Date of Birth', formatDate(e.dateOfBirth))}
          ${detailField('Address', e.address)}

          <div class="form-section-title" style="grid-column:1/-1">🔒 Identity Documents</div>
          ${detailField('Aadhaar Number', `<code>${e.aadhaarNumber || '—'}</code>`)}
          ${detailField('PAN Number', `<code>${e.panNumber || '—'}</code>`)}

          <div class="form-section-title" style="grid-column:1/-1">📅 Record Info</div>
          ${detailField('Created At', formatDate(e.createdAt))}
          ${detailField('Last Updated', formatDate(e.updatedAt))}
        </div>
      </div>`;

    // Load transfer history inline
    loadTransferHistoryInDetail(id);
  } catch (err) {
    body.innerHTML = `<div class="empty-state"><div class="empty-icon">❌</div><h3>Failed to load employee</h3><p>${err.message}</p></div>`;
  }
}

async function loadTransferHistoryInDetail(id) {
  try {
    const res = await EmployeeApi.getHistory(id);
    const history = res.data;
    if (!history.length) return;
    const body = document.getElementById('detail-body');
    const sec  = document.createElement('div');
    sec.innerHTML = `
      <div class="modal-body" style="padding-top:0">
        <div class="form-section-title" style="margin-top:0">🔄 Transfer History</div>
        <div class="table-wrapper">
          <table>
            <thead><tr>
              <th>Date</th><th>From → To</th><th>Old Code → New Code</th><th>Reason</th>
            </tr></thead>
            <tbody>
              ${history.map(h => `
              <tr>
                <td>${formatDate(h.transferDate)}</td>
                <td><div class="history-row"><span>${h.oldDepartmentName}</span><span class="history-arrow">→</span><span>${h.newDepartmentName}</span></div></td>
                <td><code>${h.oldEmployeeCode}</code> → <code class="emp-code-link">${h.newEmployeeCode}</code></td>
                <td class="text-sm text-muted">${h.transferReason}</td>
              </tr>`).join('')}
            </tbody>
          </table>
        </div>
      </div>`;
    body.appendChild(sec);
  } catch { /* ignore */ }
}

function detailField(label, value) {
  return `<div class="detail-field"><div class="detail-label">${label}</div><div class="detail-value">${value}</div></div>`;
}

// ─── Create / Edit Employee ───────────────────────────────────────────────────
function openCreateForm() {
  empState.editingId = null;
  const title = document.getElementById('form-modal-title');
  const form  = document.getElementById('emp-form');
  if (title) title.textContent = '➕ Add New Employee';
  if (form)  form.reset();
  clearAllErrors(form);
  document.getElementById('form-emp-code-display').textContent = 'Auto-generated';
  openModal('form-modal');
}

async function editEmployee(id) {
  empState.editingId = id;
  openModal('form-modal');
  document.getElementById('form-modal-title').textContent = '✏️ Edit Employee';
  try {
    const res = await EmployeeApi.getById(id);
    const e   = res.data;
    fillForm(e);
  } catch (err) {
    closeModal('form-modal');
    Toast.error('Load failed', err.message);
  }
}

function fillForm(e) {
  const set = (id, val) => { const el = document.getElementById(id); if (el) el.value = val ?? ''; };
  set('form-name',      e.fullName);
  set('form-email',     e.email);
  set('form-mobile',    e.mobileNumber);
  set('form-gender',    e.gender);
  set('form-dob',       e.dateOfBirth);
  set('form-address',   e.address);
  set('form-dept',      e.departmentId);
  set('form-role',      e.roleId);
  set('form-joining',   e.joiningDate);
  set('form-salary',    e.annualSalary);
  set('form-status',    e.employeeStatus);
  set('form-aadhaar',   e.aadhaarNumber);
  set('form-pan',       e.panNumber);
  document.getElementById('form-emp-code-display').textContent = e.employeeCode;
}

// ─── Form Validation ──────────────────────────────────────────────────────────
function validateEmployeeForm() {
  const form = document.getElementById('emp-form');
  clearAllErrors(form);
  let valid = true;

  const check = (id, fn, msg) => {
    const el = document.getElementById(id);
    if (!el) return;
    const val = el.value.trim();
    if (!fn(val)) { setFieldError(el, msg); valid = false; }
    else clearFieldError(el);
  };

  check('form-name',   v => validateName(v),   'Name must contain alphabets and spaces only.');
  check('form-email',  v => validateEmail(v),  'Please enter a valid email address.');
  check('form-mobile', v => validateMobile(v), 'Mobile number must be exactly 10 digits.');
  check('form-gender', v => v !== '',          'Please select a gender.');
  check('form-dob',    v => {
    if (!v) return false;
    return new Date(v) < new Date();
  }, 'Date of birth cannot be today or a future date.');
  check('form-address', v => v.length > 0, 'Address is required.');
  check('form-dept',    v => v !== '',     'Please select a department.');
  check('form-role',    v => v !== '',     'Please select a role.');
  check('form-joining', v => v !== '',     'Joining date is required.');
  check('form-salary',  v => parseFloat(v) > 0, 'Salary must be greater than zero.');
  check('form-aadhaar', v => validateAadhaar(v), 'Aadhaar must be in format XXXX-XXXX-XXXX.');
  check('form-pan',     v => validatePAN(v),     'PAN must be in format ABCDE1234F (e.g., ABCDE1234F).');

  return valid;
}

function wireFormEvents() {
  // Aadhaar auto-format
  const aadhaarInput = document.getElementById('form-aadhaar');
  if (aadhaarInput) {
    aadhaarInput.addEventListener('input', e => {
      const formatted = formatAadhaar(e.target.value);
      e.target.value = formatted;
    });
  }

  // PAN uppercase
  const panInput = document.getElementById('form-pan');
  if (panInput) panInput.addEventListener('input', e => { e.target.value = e.target.value.toUpperCase(); });

  // Dept → role dependency
  const deptSel = document.getElementById('form-dept');
  if (deptSel) deptSel.addEventListener('change', async e => {
    await refreshRolesByDept(e.target.value);
  });

  // Submit
  const saveBtn = document.getElementById('btn-save-emp');
  if (saveBtn) saveBtn.addEventListener('click', saveEmployee);

  // Close buttons
  qsa('[data-close-modal]').forEach(btn => {
    btn.addEventListener('click', () => closeModal(btn.dataset.closeModal));
  });
}

async function refreshRolesByDept(deptId) {
  const roleSelect = document.getElementById('form-role');
  if (!roleSelect || !deptId) return;
  try {
    const res   = await RoleApi.getByDept(deptId);
    const roles = res.data;
    roleSelect.innerHTML = '<option value="">Select Role</option>' +
      roles.map(r => `<option value="${r.roleId}">${r.roleName}</option>`).join('');
  } catch { /* use existing options */ }
}

async function saveEmployee() {
  if (!validateEmployeeForm()) {
    Toast.warning('Validation errors', 'Please fix the highlighted fields.');
    return;
  }

  const btn = document.getElementById('btn-save-emp');
  setLoading(btn, true);

  const payload = {
    fullName:      document.getElementById('form-name').value.trim(),
    email:         document.getElementById('form-email').value.trim(),
    mobileNumber:  document.getElementById('form-mobile').value.trim(),
    gender:        document.getElementById('form-gender').value,
    dateOfBirth:   document.getElementById('form-dob').value,
    address:       document.getElementById('form-address').value.trim(),
    departmentId:  parseInt(document.getElementById('form-dept').value),
    roleId:        parseInt(document.getElementById('form-role').value),
    joiningDate:   document.getElementById('form-joining').value,
    annualSalary:  parseFloat(document.getElementById('form-salary').value),
    aadhaarNumber: document.getElementById('form-aadhaar').value.trim(),
    pANNumber:     document.getElementById('form-pan').value.trim(),
  };

  if (empState.editingId) {
    payload.employeeStatus = document.getElementById('form-status').value;
  }

  try {
    if (empState.editingId) {
      await EmployeeApi.update(empState.editingId, payload);
      Toast.success('Employee Updated', 'Changes saved successfully.');
    } else {
      await EmployeeApi.create(payload);
      Toast.success('Employee Created', 'New employee added successfully.');
    }
    closeModal('form-modal');
    await loadEmployees();
  } catch (err) {
    Toast.error('Save failed', err.message);
  } finally {
    setLoading(btn, false, empState.editingId ? '💾 Update Employee' : '✅ Create Employee');
  }
}

// ─── Deactivate ───────────────────────────────────────────────────────────────
async function deactivateEmployee(id, name) {
  const confirmed = await showConfirm(
    `Deactivate ${name}?`,
    'This will set the employee status to Inactive. You can reactivate them by editing later.'
  );
  if (!confirmed) return;

  try {
    await EmployeeApi.deactivate(id);
    Toast.success('Employee Deactivated', `${name} has been deactivated.`);
    await loadEmployees();
  } catch (err) {
    Toast.error('Deactivation failed', err.message);
  }
}

// ─── Transfer ─────────────────────────────────────────────────────────────────
async function openTransfer(employeeId) {
  const emp = empState.employees.find(e => e.employeeId === employeeId);
  if (!emp) return;

  empState.transferring = emp;

  document.getElementById('tf-emp-name').textContent   = emp.fullName;
  document.getElementById('tf-current-code').textContent = emp.employeeCode;
  document.getElementById('tf-current-dept').textContent = emp.departmentName;

  // Populate new department (exclude current)
  const newDeptSel = document.getElementById('tf-new-dept');
  newDeptSel.innerHTML = '<option value="">Select Department</option>' +
    empState.departments
      .filter(d => d.departmentId !== emp.departmentId)
      .map(d => `<option value="${d.departmentId}">${d.departmentName}</option>`)
      .join('');

  document.getElementById('tf-new-role').innerHTML = '<option value="">Select Role</option>';
  document.getElementById('tf-date').value    = new Date().toISOString().slice(0, 10);
  document.getElementById('tf-reason').value  = '';

  openModal('transfer-modal');
}

function wireTransferEvents() {
  const deptSel = document.getElementById('tf-new-dept');
  if (deptSel) deptSel.addEventListener('change', async e => {
    if (!e.target.value) return;
    try {
      const res = await RoleApi.getByDept(e.target.value);
      document.getElementById('tf-new-role').innerHTML =
        '<option value="">Select Role</option>' +
        res.data.map(r => `<option value="${r.roleId}">${r.roleName}</option>`).join('');
    } catch { /* ignore */ }
  });

  const btn = document.getElementById('btn-do-transfer');
  if (btn) btn.addEventListener('click', doTransfer);
}

async function doTransfer() {
  const emp     = empState.transferring;
  const newDept = document.getElementById('tf-new-dept').value;
  const newRole = document.getElementById('tf-new-role').value;
  const date    = document.getElementById('tf-date').value;
  const reason  = document.getElementById('tf-reason').value.trim();

  if (!newDept || !newRole || !date || !reason) {
    Toast.warning('Incomplete', 'Please fill all transfer fields.');
    return;
  }

  const btn = document.getElementById('btn-do-transfer');
  setLoading(btn, true);
  try {
    const res = await EmployeeApi.transfer({
      employeeId:      emp.employeeId,
      newDepartmentId: parseInt(newDept),
      newRoleId:       parseInt(newRole),
      transferDate:    date,
      transferReason:  reason,
    });
    Toast.success('Transfer Complete', `New Employee Code: ${res.data.newEmployeeCode}`);
    closeModal('transfer-modal');
    await loadEmployees();
  } catch (err) {
    Toast.error('Transfer failed', err.message);
  } finally {
    setLoading(btn, false, '🔄 Confirm Transfer');
  }
}

// ─── Lookups ──────────────────────────────────────────────────────────────────
async function loadDepartments() {
  try {
    const res = await DeptApi.getAll();
    empState.departments = res.data;
  } catch { empState.departments = []; }
}

async function loadRoles() {
  try {
    const res = await RoleApi.getAll();
    empState.roles = res.data;
  } catch { empState.roles = []; }
}

function populateDeptFilters() {
  const sel = document.getElementById('filter-dept');
  if (!sel) return;
  sel.innerHTML = '<option value="">All Departments</option>' +
    empState.departments.map(d => `<option value="${d.departmentId}">${d.departmentName}</option>`).join('');
}

function populateRoleFilters() {
  const sel = document.getElementById('filter-role');
  if (!sel) return;
  sel.innerHTML = '<option value="">All Roles</option>' +
    empState.roles.map(r => `<option value="${r.roleId}">${r.roleName}</option>`).join('');
}

function populateDeptFormOptions() {
  const sel = document.getElementById('form-dept');
  if (!sel) return;
  sel.innerHTML = '<option value="">Select Department</option>' +
    empState.departments.map(d => `<option value="${d.departmentId}">${d.departmentName}</option>`).join('');
}

function populateRoleFormOptions() {
  const sel = document.getElementById('form-role');
  if (!sel) return;
  sel.innerHTML = '<option value="">Select Role</option>' +
    empState.roles.map(r => `<option value="${r.roleId}">${r.roleName}</option>`).join('');
}

function populateSalaryRanges() {
  const sel = document.getElementById('filter-salary-range');
  if (!sel) return;
  sel.innerHTML = CONFIG.SALARY_RANGES.map((r, i) =>
    `<option value="${i}">${r.label}</option>`
  ).join('');
}

// ─── Stats ────────────────────────────────────────────────────────────────────
function updateStats() {
  const total  = document.getElementById('stat-total');
  const active = document.getElementById('stat-active');
  if (total)  total.textContent  = empState.totalCount;
}

// ─── Loading ──────────────────────────────────────────────────────────────────
function showTableLoading(show) {
  const overlay = document.getElementById('table-loading');
  if (overlay) overlay.classList.toggle('hidden', !show);
}
