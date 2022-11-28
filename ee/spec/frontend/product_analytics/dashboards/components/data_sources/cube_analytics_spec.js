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
  describe('fetch', () => {
    let result;

    beforeEach(async () => {
      result = await fetch('TEST_ID', { alpha: 'one' }, { alpha: 'two' });
    });

    afterEach(() => {
      result = null;
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

    it('returns the data in the expected charts format', () => {
      expect(result[0]).toMatchObject({
        data: [
          ['2022-11-09T00:00:00.000', 55],
          ['2022-11-10T00:00:00.000', 14],
        ],
        name: 'pageview, Jitsu Count',
      });
    });
  });
});
