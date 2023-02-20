import {
  getFailedChecksWithLoadingState,
  mapStatusCheckResponse,
} from 'ee/vue_merge_request_widget/extensions/status_checks/mappers';

describe('status checks widget extension mappers', () => {
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

  describe('mapStatusCheckResponse', () => {
    let mockRetryCb;

    beforeEach(() => {
      mockRetryCb = jest.fn();
    });

    function getMockResponse(status) {
      return {
        data: [{ id: 1, status, name: 'some check', external_url: 'https://example.com' }],
      };
    }

    it('maps passed checks as expected', () => {
      const mockResponse = getMockResponse('passed');
      const options = { canRetry: true };

      const { approved, pending, failed } = mapStatusCheckResponse(
        mockResponse,
        options,
        mockRetryCb,
      );

      expect(pending).toHaveLength(0);
      expect(failed).toHaveLength(0);
      expect(approved).toHaveLength(1);
      expect(approved[0]).toMatchObject({
        id: 1,
        text: 'some check: https://example.com',
        icon: { name: 'success' },
      });
    });

    it('maps pending checks as expected', () => {
      const mockResponse = getMockResponse('pending');
      const options = { canRetry: true };

      const { approved, pending, failed } = mapStatusCheckResponse(
        mockResponse,
        options,
        mockRetryCb,
      );

      expect(approved).toHaveLength(0);
      expect(failed).toHaveLength(0);
      expect(pending).toHaveLength(1);
      expect(pending[0]).toMatchObject({
        id: 1,
        text: 'some check: https://example.com',
        icon: { name: 'neutral' },
      });
    });

    it('maps failed checks as expected', () => {
      const mockResponse = getMockResponse('failed');
      const options = { canRetry: true };

      const { approved, pending, failed } = mapStatusCheckResponse(
        mockResponse,
        options,
        mockRetryCb,
      );

      expect(approved).toHaveLength(0);
      expect(pending).toHaveLength(0);
      expect(failed).toHaveLength(1);
      expect(failed[0]).toMatchObject({
        id: 1,
        text: 'some check: https://example.com',
        icon: { name: 'failed' },
        actions: [
          expect.objectContaining({
            icon: 'retry',
            text: 'Retry',
          }),
        ],
      });
    });

    it('maps failed checks without a retry action when user cannot retry', () => {
      const mockResponse = getMockResponse('failed');
      const options = { canRetry: false };

      const { approved, pending, failed } = mapStatusCheckResponse(
        mockResponse,
        options,
        mockRetryCb,
      );

      expect(approved).toHaveLength(0);
      expect(pending).toHaveLength(0);
      expect(failed).toHaveLength(1);
      expect(failed[0]).toMatchObject({
        id: 1,
        text: 'some check: https://example.com',
        icon: { name: 'failed' },
      });
      expect(failed[0].actions).toBeUndefined();
    });
  });
});
