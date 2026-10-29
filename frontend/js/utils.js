// ============================================================
//  utils.js — Shared helper functions
// ============================================================

// ─── Toast Notifications ──────────────────────────────────────────────────────
const Toast = (() => {
  let container;

  function getContainer() {
    if (!container) {
      container = document.createElement('div');
      container.className = 'toast-container';
      document.body.appendChild(container);
    }
    return container;
  }

  const ICONS = {
    success: '✅',
    error:   '❌',
    warning: '⚠️',
    info:    'ℹ️',
  };

  function show(type, title, message = '', duration = 4000) {
    const c = getContainer();
    const t = document.createElement('div');
    t.className = `toast ${type}`;
    t.innerHTML = `
      <span class="toast-icon">${ICONS[type] || 'ℹ️'}</span>
      <div class="toast-content">
        <div class="toast-title">${title}</div>
        ${message ? `<div class="toast-msg">${message}</div>` : ''}
      </div>
      <span class="toast-close" title="Dismiss">×</span>
    `;
    c.appendChild(t);
    t.querySelector('.toast-close').addEventListener('click', () => remove(t));
    if (duration > 0) setTimeout(() => remove(t), duration);
  }

  function remove(el) {
    el.classList.add('removing');
    el.addEventListener('animationend', () => el.remove());
  }

  return {
    success: (title, msg)  => show('success', title, msg),
    error:   (title, msg)  => show('error',   title, msg),
    warning: (title, msg)  => show('warning', title, msg),
    info:    (title, msg)  => show('info',    title, msg),
  };
})();

// ─── Formatting ───────────────────────────────────────────────────────────────
function formatCurrency(amount) {
  if (amount == null) return '—';
  return new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', maximumFractionDigits: 0 }).format(amount);
}

function formatDate(dateStr) {
  if (!dateStr) return '—';
  const d = new Date(dateStr);
  return d.toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' });
}

function formatAadhaar(raw) {
  const digits = raw.replace(/\D/g, '').slice(0, 12);
  return digits.replace(/(\d{4})(\d{0,4})(\d{0,4})/, (_, a, b, c) =>
    [a, b, c].filter(Boolean).join('-'));
}

function validateAadhaar(val) {
  return /^\d{4}-\d{4}-\d{4}$/.test(val);
}

function validatePAN(val) {
  return /^[A-Z]{5}[0-9]{4}[A-Z]$/.test(val);
}

function validateMobile(val) {
  return /^\d{10}$/.test(val);
}

function validateEmail(val) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(val);
}

function validateName(val) {
  return /^[A-Za-z ]+$/.test(val.trim()) && val.trim().length > 0;
}

function getInitials(name) {
  return name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2);
}

function lpaLabel(salary) {
  const lpa = salary / 100000;
  return `₹${lpa.toFixed(1)} LPA`;
}

// ─── DOM Helpers ──────────────────────────────────────────────────────────────
function qs(sel, ctx = document) { return ctx.querySelector(sel); }
function qsa(sel, ctx = document) { return [...ctx.querySelectorAll(sel)]; }

function setFieldError(inputEl, msg) {
  inputEl.classList.add('error');
  let errEl = inputEl.parentElement.querySelector('.form-error');
  if (!errEl) {
    errEl = document.createElement('span');
    errEl.className = 'form-error';
    inputEl.after(errEl);
  }
  errEl.textContent = `⚠ ${msg}`;
}

function clearFieldError(inputEl) {
  inputEl.classList.remove('error');
  const errEl = inputEl.parentElement.querySelector('.form-error');
  if (errEl) errEl.remove();
}

function clearAllErrors(form) {
  qsa('.form-control.error, .form-select.error', form).forEach(el => el.classList.remove('error'));
  qsa('.form-error', form).forEach(el => el.remove());
}

function setLoading(btn, loading, text = null) {
  if (loading) {
    btn._origText = btn.innerHTML;
    btn.innerHTML = '<span class="spinner" style="width:16px;height:16px;border-width:2px;margin:0 4px"></span>';
    btn.disabled = true;
  } else {
    btn.innerHTML = text || btn._origText || btn.innerHTML;
    btn.disabled = false;
  }
}

// ─── Modal Helper ─────────────────────────────────────────────────────────────
function openModal(id) {
  const overlay = document.getElementById(id);
  if (overlay) { overlay.classList.add('open'); document.body.style.overflow = 'hidden'; }
}

function closeModal(id) {
  const overlay = document.getElementById(id);
  if (overlay) { overlay.classList.remove('open'); document.body.style.overflow = ''; }
}

// Close on overlay click
document.addEventListener('click', e => {
  if (e.target.classList.contains('modal-overlay')) closeModal(e.target.id);
});

// ─── Debounce ────────────────────────────────────────────────────────────────
function debounce(fn, ms = 300) {
  let timer;
  return (...args) => { clearTimeout(timer); timer = setTimeout(() => fn(...args), ms); };
}

// ─── Build sidebar user info ──────────────────────────────────────────────────
function renderSidebarUser() {
  const user = Auth.getUser();
  if (!user) return;
  const nameEl = document.getElementById('sidebar-user-name');
  const roleEl = document.getElementById('sidebar-user-role');
  const avatarEl = document.getElementById('sidebar-avatar');
  if (nameEl) nameEl.textContent = user.email.split('@')[0];
  if (roleEl) roleEl.textContent = user.role;
  if (avatarEl) avatarEl.textContent = user.email[0].toUpperCase();
}

// ─── Highlight active nav item ────────────────────────────────────────────────
function setActiveNav(page) {
  qsa('.nav-item').forEach(el => {
    el.classList.toggle('active', el.dataset.page === page);
  });
}

// ─── Confirm dialog ───────────────────────────────────────────────────────────
function showConfirm(title, message) {
  return new Promise(resolve => {
    let overlay = document.getElementById('confirm-dialog');
    if (!overlay) {
      overlay = document.createElement('div');
      overlay.id = 'confirm-dialog';
      overlay.className = 'modal-overlay confirm-dialog';
      overlay.innerHTML = `
        <div class="modal" style="max-width:420px">
          <div class="modal-body">
            <div class="confirm-icon-wrap">⚠️</div>
            <h4 id="confirm-title"></h4>
            <p id="confirm-msg"></p>
          </div>
          <div class="modal-footer" style="justify-content:center;gap:12px">
            <button id="confirm-cancel" class="btn btn-outline">Cancel</button>
            <button id="confirm-ok" class="btn btn-danger">Confirm</button>
          </div>
        </div>`;
      document.body.appendChild(overlay);
    }
    document.getElementById('confirm-title').textContent = title;
    document.getElementById('confirm-msg').textContent   = message;
    openModal('confirm-dialog');

    const cleanup = (val) => {
      closeModal('confirm-dialog');
      resolve(val);
    };

    document.getElementById('confirm-ok').onclick     = () => cleanup(true);
    document.getElementById('confirm-cancel').onclick = () => cleanup(false);
  });
}
