// ============================================================
//  api.js — Centralised HTTP client with JWT auth
// ============================================================

const Api = (() => {
  const getToken = () => localStorage.getItem('emp_token');

  async function request(method, path, body = null) {
    const token = getToken();
    const headers = { 'Content-Type': 'application/json' };
    if (token) headers['Authorization'] = `Bearer ${token}`;

    const opts = { method, headers };
    if (body) opts.body = JSON.stringify(body);

    const res = await fetch(`${CONFIG.API_BASE}${path}`, opts);

    if (res.status === 401) {
      Auth.logout();
      throw new Error('Session expired. Please login again.');
    }

    const json = await res.json().catch(() => ({ success: false, message: res.statusText }));

    if (!res.ok) {
      throw new Error(json.message || `HTTP ${res.status}`);
    }

    return json;
  }

  return {
    get:    (path)        => request('GET',    path),
    post:   (path, body)  => request('POST',   path, body),
    put:    (path, body)  => request('PUT',    path, body),
    delete: (path)        => request('DELETE', path),
  };
})();

// ─── Auth API ─────────────────────────────────────────────────────────────────
const AuthApi = {
  login: (email, password) => Api.post('/auth/login', { email, password }),
};

// ─── Employees API ────────────────────────────────────────────────────────────
const EmployeeApi = {
  getAll:          (params)     => Api.get('/employees?' + new URLSearchParams(params).toString()),
  getById:         (id)         => Api.get(`/employees/${id}`),
  create:          (data)       => Api.post('/employees', data),
  update:          (id, data)   => Api.put(`/employees/${id}`, data),
  deactivate:      (id)         => Api.delete(`/employees/${id}`),
  transfer:        (data)       => Api.post('/employees/transfer', data),
  getHistory:      (id)         => Api.get(`/employees/${id}/transfer-history`),
};

// ─── Lookup APIs ──────────────────────────────────────────────────────────────
const DeptApi = {
  getAll: ()     => Api.get('/departments'),
};

const RoleApi = {
  getAll:       ()       => Api.get('/roles'),
  getByDept:    (deptId) => Api.get(`/roles?departmentId=${deptId}`),
};
