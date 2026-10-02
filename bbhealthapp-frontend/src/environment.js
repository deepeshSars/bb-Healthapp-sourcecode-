// ===============================
// FRONTEND ENV CONFIG (FIXED)
// ===============================

// MUST start with REACT_APP_ in .env
const docSvc = process.env.REACT_APP_DOCSVC_HOST;
const regSvc = process.env.REACT_APP_REGSVC_HOST;
const masterSvc = process.env.REACT_APP_MASTERSVC_HOST;

export const environment = {
  // MASTER SERVICE
  MASTER_HOST_URL: `http://${masterSvc}:8080`,

  // AUTH / REGISTER SERVICE
  REGISTER_BASE_URL: `http://${regSvc}:8082`,
  LOGIN_URL: `http://${masterSvc}:8080/auth/login`,
  REGISTER_URL: `http://${regSvc}:8082/auth/register`,
  DOCTOR_REGISTER_URL: `http://${regSvc}:8082/auth/doctor/register`,
  TESTER_REGISTER_URL: `http://${regSvc}:8082/auth/tester/register`,

  // DOCUMENT SERVICE
  DOCUMENT_BASE_URL: `http://${docSvc}:8083`,
  DOCUMENT_UPLOAD_URL: `http://${docSvc}:8083/documents/upload`,
  DOCUMENT_DOWNLOAD_URL: `http://${docSvc}:8083/documents/download`,
};