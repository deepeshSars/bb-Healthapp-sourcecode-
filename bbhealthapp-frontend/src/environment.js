// ===============================
// FRONTEND ENV CONFIG (FIXED)
// ===============================

// MUST start with REACT_APP_ in .env or default to the provisioned AWS ELBs
const docSvc = process.env.REACT_APP_DOCSVC_HOST || "a951a9c4a4d784f3dbf4382929882f8d-744204313.ap-south-1.elb.amazonaws.com:8083";
const regSvc = process.env.REACT_APP_REGSVC_HOST || "af1659a970b7f450bb4256683b7bbc51-1930909170.ap-south-1.elb.amazonaws.com:8082";
const masterSvc = process.env.REACT_APP_MASTERSVC_HOST || "ad2a6fd6a8ed94d2eb29dab1e12867c2-518173443.ap-south-1.elb.amazonaws.com:8081";

const formatUrl = (host) => (host.startsWith("http://") || host.startsWith("https://")) ? host : `http://${host}`;

const masterBase = formatUrl(masterSvc);
const regBase = formatUrl(regSvc);
const docBase = formatUrl(docSvc);

export const environment = {
  // GENERAL BASE URL (Used across dispatchers for /api/...)
  baseUrl: masterBase,

  // MASTER SERVICE
  MASTER_HOST_URL: masterBase,
  LOGIN_URL: `${masterBase}/auth/login`,

  // AUTH / REGISTER SERVICE
  REGISTER_BASE_URL: regBase,
  REGISTER_URL: `${regBase}/auth/register`,
  DOCTOR_REGISTER_URL: `${regBase}/auth/doctor/register`,
  TESTER_REGISTER_URL: `${regBase}/auth/tester/register`,

  // DOCUMENT SERVICE
  DOCUMENT_BASE_URL: docBase,
  DOWNLOAD_BASE_URL: `${docBase}/documents/download/`,
  DOCUMENT_UPLOAD_URL: `${docBase}/documents/upload/`,
  DOCUMENT_DOWNLOAD_URL: `${docBase}/documents/download/`,
};