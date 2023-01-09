import { getFailedChecksWithLoadingState } from 'ee/vue_merge_request_widget/extensions/status_checks/get_failed_checks_with_loading_state';

describe('status checks widget extension utils', () => {
  describe('getFailedChecksWithLoadingState', () => {
    it('should not modify other status checks', () => {
      const failedStatusChecks = [{ id: 1 }, { id: 2, actions: [{ icon: 'retry' }] }];
      const statusCheckId = 2;
      const result = getFailedChecksWithLoadingState(failedStatusChecks, statusCheckId);

      expect(result[0]).toBe(failedStatusChecks[0]);
    });

    it('should set loading and disabled properties and remove icon', () => {
      const failedStatusChecks = [{ id: 1 }, { id: 2, actions: [{ icon: 'retry' }] }];

      const statusCheckId = 2;
      const result = getFailedChecksWithLoadingState(failedStatusChecks, statusCheckId);

      const action = result[1]?.actions[0];

      expect(action).toStrictEqual(expect.objectContaining({ loading: true, disabled: true }));
    });
  });
});
