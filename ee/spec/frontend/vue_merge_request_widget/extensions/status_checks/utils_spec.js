import { responseHasPendingChecks } from 'ee/vue_merge_request_widget/extensions/status_checks/utils';
import { FAILED, PASSED, PENDING } from 'ee/ci/reports/status_checks_report/constants';

describe('status checks widget extension utils', () => {
  describe('responseHasPendingChecks', () => {
    it('returns true when there is a pending check', () => {
      const response = {
        data: [
          { id: 1, status: FAILED },
          { id: 2, status: PENDING },
          { id: 3, status: PASSED },
        ],
      };
      const result = responseHasPendingChecks(response);

      expect(result).toBe(true);
    });

    it('returns false when there are no pending checks', () => {
      const response = {
        data: [
          { id: 1, status: FAILED },
          { id: 2, status: FAILED },
          { id: 3, status: PASSED },
        ],
      };
      const result = responseHasPendingChecks(response);

      expect(result).toBe(false);
    });
  });
});
