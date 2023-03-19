import {
  getFailedChecksWithLoadingState,
  mapStatusCheckResponse,
} from 'ee/vue_merge_request_widget/extensions/status_checks/mappers';

const TEST_STATUS_RESPONSE = {
  id: 1,
  name: 'some check',
  external_url: 'https://example.com',
};
const EXPECTATION_STATUS = {
  id: 1,
  text: 'some check: %{small_start}https://example.com%{small_end}',
  subtext: '%{small_start}Status Check ID: 1%{small_end}',
};

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
    let mockRetryCallback;

    beforeEach(() => {
      mockRetryCallback = jest.fn();
    });

    function getMockResponse(status) {
      return {
        data: [{ ...TEST_STATUS_RESPONSE, status }],
      };
    }

    it('maps passed checks as expected', () => {
      const mockResponse = getMockResponse('passed');
      const options = { canRetry: true };

      const result = mapStatusCheckResponse(mockResponse, options, mockRetryCallback);

      expect(result).toEqual({
        pending: [],
        failed: [],
        approved: [
          {
            ...EXPECTATION_STATUS,
            icon: { name: 'success' },
          },
        ],
      });
    });

    it('maps pending checks as expected', () => {
      const mockResponse = getMockResponse('pending');
      const options = { canRetry: true };

      const result = mapStatusCheckResponse(mockResponse, options, mockRetryCallback);

      expect(result).toEqual({
        approved: [],
        failed: [],
        pending: [
          {
            ...EXPECTATION_STATUS,
            icon: { name: 'neutral' },
          },
        ],
      });
    });

    it('maps failed checks as expected', () => {
      const mockResponse = getMockResponse('failed');
      const options = { canRetry: true };

      const result = mapStatusCheckResponse(mockResponse, options, mockRetryCallback);

      expect(result).toEqual({
        approved: [],
        pending: [],
        failed: [
          {
            ...EXPECTATION_STATUS,
            actions: [
              {
                icon: 'retry',
                text: 'Retry',
                onClick: expect.any(Function),
              },
            ],
            icon: { name: 'failed' },
          },
        ],
      });
    });

    it('maps failed checks without a retry action when user cannot retry', () => {
      const mockResponse = getMockResponse('failed');
      const options = { canRetry: false };

      const result = mapStatusCheckResponse(mockResponse, options, mockRetryCallback);

      expect(result).toEqual({
        approved: [],
        pending: [],
        failed: [
          {
            ...EXPECTATION_STATUS,
            icon: { name: 'failed' },
          },
        ],
      });
    });
  });
});
