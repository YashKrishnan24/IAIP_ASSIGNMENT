// ============================================================
//  config.js — API base URL and app-wide constants
// ============================================================

const CONFIG = {
  API_BASE: 'http://localhost:5000/api',   // ← change to your backend URL
  APP_NAME: 'EmpManager Pro',
  PAGE_SIZES: [5, 10, 20],
  SALARY_RANGES: [
    { label: 'All Salaries',   min: null,    max: null },
    { label: '₹1–3 LPA',      min: 100000,  max: 300000 },
    { label: '₹3–5 LPA',      min: 300000,  max: 500000 },
    { label: '₹5–10 LPA',     min: 500000,  max: 1000000 },
    { label: '₹10+ LPA',      min: 1000000, max: null },
    { label: 'Custom Range',   min: 'custom',max: 'custom' },
  ],
};
