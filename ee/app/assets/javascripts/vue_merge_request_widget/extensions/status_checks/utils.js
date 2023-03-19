import { PENDING } from 'ee/ci/reports/status_checks_report/constants';

export function responseHasPendingChecks(response) {
  return response.data.some((statusCheck) => statusCheck.status === PENDING);
}
