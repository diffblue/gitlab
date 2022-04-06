import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import axios from '~/lib/utils/axios_utils';
import statusCodes from '~/lib/utils/http_status';
import { fetchFunctions, fetchMetrics } from '~/serverless/store/actions';
import { mockServerlessFunctions, mockMetrics } from '../mock_data';
import { adjustMetricQuery } from '../utils';

describe('ServerlessActions', () => {
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('fetchFunctions', () => {
    it('should successfully fetch functions', async () => {
      const endpoint = '/functions';
      mock.onGet(endpoint).reply(statusCodes.OK, JSON.stringify(mockServerlessFunctions));

      await testAction(
        fetchFunctions,
        { functionsPath: endpoint },
        {},
        [],
        [
          { type: 'requestFunctionsLoading' },
          { type: 'receiveFunctionsSuccess', payload: mockServerlessFunctions },
        ],
      );
    });

    it('should successfully retry', async () => {
      const endpoint = '/functions';
      mock
        .onGet(endpoint)
        .reply(() => new Promise((resolve) => setTimeout(() => resolve(200), Infinity)));

      await testAction(
        fetchFunctions,
        { functionsPath: endpoint },
        {},
        [],
        [{ type: 'requestFunctionsLoading' }],
      );
    });
  });

  describe('fetchMetrics', () => {
    it('should return no prometheus', async () => {
      const endpoint = '/metrics';
      mock.onGet(endpoint).reply(statusCodes.NO_CONTENT);

      await testAction(
        fetchMetrics,
        { metricsPath: endpoint, hasPrometheus: false },
        {},
        [],
        [{ type: 'receiveMetricsNoPrometheus' }],
      );
    });

    it('should successfully fetch metrics', async () => {
      const endpoint = '/metrics';
      mock.onGet(endpoint).reply(statusCodes.OK, JSON.stringify(mockMetrics));

      await testAction(
        fetchMetrics,
        { metricsPath: endpoint, hasPrometheus: true },
        {},
        [],
        [{ type: 'receiveMetricsSuccess', payload: adjustMetricQuery(mockMetrics) }],
      );
    });
  });
});
