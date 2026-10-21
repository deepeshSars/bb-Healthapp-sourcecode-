// ===============================
// FRONTEND ENV CONFIG (FIXED)
// ===============================

// MUST start with REACT_APP_ in .env or default to the provisioned AWS ELBs
const docSvc = process.env.REACT_APP_DOCSVC_HOST || "aef42fd2a78724cb88a8e31f66e61a99-1787005417.ap-south-1.elb.amazonaws.com:8083";
const regSvc = process.env.REACT_APP_REGSVC_HOST || "a6a9b5014957247d28c0969042a9841b-918609063.ap-south-1.elb.amazonaws.com:8082";
const masterSvc = process.env.REACT_APP_MASTERSVC_HOST || "a445649e7fa784acb87d5a69be9f066c-541123145.ap-south-1.elb.amazonaws.com:8081";

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