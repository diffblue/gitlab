import * as DoraApi from 'ee/api/dora_api';
import axios from '~/lib/utils/axios_utils';

jest.mock('~/lib/utils/axios_utils', () => ({
  get: jest.fn(),
}));

describe('dora_api.js', () => {
  const dummyApiVersion = 'v3000';
  const dummyUrlRoot = '/gitlab';

  beforeEach(() => {
    window.gon = {
      api_version: dummyApiVersion,
      relative_url_root: dummyUrlRoot,
    };
  });

  describe.each`
    functionName               | baseUrl
    ${'getProjectDoraMetrics'} | ${`${dummyUrlRoot}/api/${dummyApiVersion}/projects`}
    ${'getGroupDoraMetrics'}   | ${`${dummyUrlRoot}/api/${dummyApiVersion}/groups`}
  `('$functionName', ({ functionName, baseUrl }) => {
    it.each`
      id                    | metric                                      | params                  | url
      ${1}                  | ${DoraApi.DEPLOYMENT_FREQUENCY_METRIC_TYPE} | ${undefined}            | ${`${baseUrl}/1/dora/metrics`}
      ${1}                  | ${DoraApi.LEAD_TIME_FOR_CHANGES}            | ${undefined}            | ${`${baseUrl}/1/dora/metrics`}
      ${1}                  | ${DoraApi.DEPLOYMENT_FREQUENCY_METRIC_TYPE} | ${{ another: 'param' }} | ${`${baseUrl}/1/dora/metrics`}
      ${'name with spaces'} | ${DoraApi.DEPLOYMENT_FREQUENCY_METRIC_TYPE} | ${undefined}            | ${`${baseUrl}/name%20with%20spaces/dora/metrics`}
    `(`makes a call to $url with the correct params`, ({ id, metric, params, url }) => {
      DoraApi[functionName](id, metric, params);

      expect(axios.get.mock.calls).toEqual([
        [
          url,
          {
            params: {
              metric,
              ...params,
            },
          },
        ],
      ]);
    });

    it('throws an error when an invalid metric type is provided', () => {
      const callFunction = () => DoraApi[functionName](1, 'invalid_metric_type');

      expect(callFunction).toThrow('Unsupported metric type: "invalid_metric_type"');

      expect(axios.get).not.toHaveBeenCalled();
    });
  });
});
