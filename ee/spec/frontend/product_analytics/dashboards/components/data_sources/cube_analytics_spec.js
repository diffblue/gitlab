import { CubejsApi, HttpTransport } from '@cubejs-client/core';
import { fetch } from 'ee/product_analytics/dashboards/data_sources/cube_analytics';
import { mockResultSet } from '../mock_data';

const mockLoad = jest.fn().mockImplementation(() => mockResultSet);

jest.mock('@cubejs-client/core', () => ({
  CubejsApi: jest.fn().mockImplementation(() => ({
    load: mockLoad,
  })),
  HttpTransport: jest.fn(),
}));

jest.mock('~/lib/utils/csrf', () => ({
  headerKey: 'mock-csrf-header',
  token: 'mock-csrf-token',
}));

describe('Cube Analytics Data Source', () => {
  const projectId = 'TEST_ID';
  const visualizationType = 'LineChart';
  const query = { alpha: 'one' };
  const queryOverrides = { alpha: 'two' };

  describe('fetch', () => {
    beforeEach(() => {
      return fetch({ projectId, visualizationType, query, queryOverrides });
    });

    it('creates a new CubejsApi connection', () => {
      expect(CubejsApi).toHaveBeenCalledWith('1', { transport: {} });
    });

    it('creates a new HttpTransport with the proxy URL and csrf headers', () => {
      expect(HttpTransport).toHaveBeenCalledWith(
        expect.objectContaining({
          apiUrl: '/api/v4/projects/TEST_ID/product_analytics/request',
          headers: expect.objectContaining({
            'mock-csrf-header': 'mock-csrf-token',
          }),
        }),
      );
    });

    it('loads the query with the query override', () => {
      expect(mockLoad).toHaveBeenCalledWith({ alpha: 'two' });
    });

    describe('formarts the data', () => {
      it('returns the expected data format for line charts', async () => {
        const result = await fetch({ projectId, visualizationType, query });

        expect(result[0]).toMatchObject({
          data: [
            ['2022-11-09T00:00:00.000', 55],
            ['2022-11-10T00:00:00.000', 14],
          ],
          name: 'pageview, Jitsu Count',
        });
      });

      it('returns the expected data format for data tables', async () => {
        const result = await fetch({ projectId, visualizationType: 'DataTable', query });

        expect(result[0]).toMatchObject({
          count: '55',
          event_type: 'pageview',
          utc_time: '2022-11-09T00:00:00.000',
        });
      });

      it('returns the expected data format for single stats', async () => {
        const result = await fetch({ projectId, visualizationType: 'SingleStat', query });

        expect(result).toBe('36');
      });
    });
  });
});
