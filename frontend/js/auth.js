// ============================================================
//  auth.js — Auth state management
// ============================================================

const Auth = (() => {
  const TOKEN_KEY  = 'emp_token';
  const USER_KEY   = 'emp_user';

  function save(loginResponse) {
    const { data } = loginResponse;
    localStorage.setItem(TOKEN_KEY, data.token);
    localStorage.setItem(USER_KEY, JSON.stringify({
      email:      data.email,
      role:       data.userRole,
      employeeId: data.employeeId,
      expiresAt:  data.expiresAt,
    }));
  }

  function logout() {
    localStorage.removeItem(TOKEN_KEY);
    localStorage.removeItem(USER_KEY);
    window.location.href = 'login.html';
  }

  function getUser() {
    try { return JSON.parse(localStorage.getItem(USER_KEY) || 'null'); }
    catch { return null; }
  }

  function isLoggedIn() {
    const token = localStorage.getItem(TOKEN_KEY);
    const user  = getUser();
    if (!token || !user) return false;
    if (new Date(user.expiresAt) < new Date()) { logout(); return false; }
    return true;
  }

  function requireAuth() {
    if (!isLoggedIn()) { window.location.href = 'login.html'; }
  }

  function isAdmin()   { return getUser()?.role === 'Admin'; }
  function isManager() { const r = getUser()?.role; return r === 'Admin' || r === 'Manager'; }

  return { save, logout, getUser, isLoggedIn, requireAuth, isAdmin, isManager };
})();
