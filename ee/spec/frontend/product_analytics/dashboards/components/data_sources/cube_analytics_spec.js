import { CubejsApi, HttpTransport } from '@cubejs-client/core';
import {
  fetch,
  hasAnalyticsData,
  NO_DATABASE_ERROR_MESSAGE,
} from 'ee/product_analytics/dashboards/data_sources/cube_analytics';
import { mockCountResultSet, mockResultSet } from '../mock_data';

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

const itSetsUpCube = () => {
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
};

describe('Cube Analytics Data Source', () => {
  const projectId = 'TEST_ID';
  const visualizationType = 'LineChart';
  const query = { measures: ['Jitsu.count'] };
  const queryOverrides = { measures: ['Jitsu.userLanguage'] };

  describe('fetch', () => {
    beforeEach(() => {
      return fetch({ projectId, visualizationType, query, queryOverrides });
    });

    itSetsUpCube();

    it('loads the query with the query override', () => {
      expect(mockLoad).toHaveBeenCalledWith(queryOverrides);
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

      it('returns the expected data format for single stats with custom measure', async () => {
        const override = { measures: ['Jitsu.url'] };
        const result = await fetch({
          projectId,
          visualizationType: 'SingleStat',
          query,
          queryOverrides: override,
        });

        expect(result).toBe('https://example.com/us');
      });

      it('returns the expected data format for single stats when the measure is unknown', async () => {
        const override = { measures: ['unknown'] };
        const result = await fetch({
          projectId,
          visualizationType: 'SingleStat',
          query,
          queryOverrides: override,
        });

        expect(result).toBe('en-US');
      });
    });
  });

  describe('hasAnalyticsData', () => {
    let result;

    afterEach(() => {
      result = null;
    });

    describe.each`
      countText           | mockedApiResponse          | expectedResult
      ${'greater than 0'} | ${mockCountResultSet(335)} | ${true}
      ${'equal to 0'}     | ${mockCountResultSet(0)}   | ${false}
    `('when the amount of data is $countText', ({ mockedApiResponse, expectedResult }) => {
      beforeEach(async () => {
        mockLoad.mockImplementation(() => mockedApiResponse);

        result = await hasAnalyticsData('TEST_ID');
      });

      itSetsUpCube();

      it(`should return ${expectedResult}`, () => {
        expect(result).toBe(expectedResult);
      });
    });

    describe(`when the API returns ${NO_DATABASE_ERROR_MESSAGE}`, () => {
      beforeEach(async () => {
        mockLoad.mockRejectedValue({ response: { message: NO_DATABASE_ERROR_MESSAGE } });

        result = await hasAnalyticsData('TEST_ID');
      });

      itSetsUpCube();

      it('should return false', async () => {
        expect(result).toBe(false);
      });
    });

    describe(`when the API returns an unexpected error`, () => {
      const error = new Error('unexpected error');

      it('should throw the error', async () => {
        mockLoad.mockRejectedValue(error);

        await expect(hasAnalyticsData('TEST_ID')).rejects.toThrow(error);
      });
    });
  });
});
