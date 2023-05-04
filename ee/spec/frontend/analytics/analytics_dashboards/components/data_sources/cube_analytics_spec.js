import { CubejsApi, HttpTransport, __setMockLoad } from '@cubejs-client/core';
import { fetch } from 'ee/analytics/analytics_dashboards/data_sources/cube_analytics';
import { pikadayToString } from '~/lib/utils/datetime_utility';
import { mockResultSet, mockFilters, mockTableWithLinksResultSet } from '../../mock_data';

const mockLoad = jest.fn().mockImplementation(() => mockResultSet);

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
  beforeEach(() => {
    __setMockLoad(mockLoad);
  });
  const projectId = 'TEST_ID';
  const visualizationType = 'LineChart';
  const query = { measures: ['TrackedEvents.count'] };
  const queryOverrides = { measures: ['TrackedEvents.userLanguage'] };

  describe('fetch', () => {
    beforeEach(() => {
      return fetch({ projectId, visualizationType, query, queryOverrides });
    });

    itSetsUpCube();

    it('loads the query with the query override', () => {
      expect(mockLoad).toHaveBeenCalledWith(queryOverrides);
    });

    describe('formats the data', () => {
      it('returns the expected data format for line charts', async () => {
        const result = await fetch({ projectId, visualizationType, query });

        expect(result[0]).toMatchObject({
          data: [
            ['2022-11-09T00:00:00.000', 55],
            ['2022-11-10T00:00:00.000', 14],
          ],
          name: 'pageview, TrackedEvents Count',
        });
      });

      it('returns the expected data format for column charts', async () => {
        const result = await fetch({ projectId, visualizationType: 'ColumnChart', query });

        expect(result[0]).toMatchObject({
          data: [
            ['2022-11-09T00:00:00.000', 55],
            ['2022-11-10T00:00:00.000', 14],
          ],
          name: 'pageview, TrackedEvents Count',
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

      it('returns the expected data format for data tables when links config is defined', async () => {
        mockLoad.mockImplementationOnce(() => mockTableWithLinksResultSet);

        const result = await fetch({
          projectId,
          visualizationType: 'DataTable',
          query: {
            measures: ['TrackedEvents.pageViewsCount'],
            dimensions: ['TrackedEvents.docPath', 'TrackedEvents.url'],
          },
          visualizationOptions: {
            links: [
              {
                text: 'TrackedEvents.docPath',
                href: 'TrackedEvents.url',
              },
            ],
          },
        });

        expect(result[0]).toMatchObject({
          page_views_count: '1',
          doc_path: {
            text: '/foo',
            href: 'https://example.com/foo',
          },
        });
      });

      it('returns the expected data format for single stats', async () => {
        const result = await fetch({ projectId, visualizationType: 'SingleStat', query });

        expect(result).toBe('36');
      });

      it('returns the expected data format for single stats with custom measure', async () => {
        const override = { measures: ['TrackedEvents.url'] };
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

  describe('fetch with filters', () => {
    const existingFilters = [
      {
        operator: 'equals',
        values: ['pageview'],
        member: 'TrackedEvents.eventType',
      },
    ];

    it.each`
      type               | queryMeasurement         | expectedDimension
      ${'TrackedEvents'} | ${'TrackedEvents.count'} | ${'TrackedEvents.utcTime'}
      ${'Sessions'}      | ${'Sessions.count'}      | ${'Sessions.startAt'}
    `(
      'loads the query with date range filters for "$type"',
      async ({ queryMeasurement, expectedDimension }) => {
        await fetch({
          projectId,
          visualizationType,
          query: {
            filters: existingFilters,
            measures: [queryMeasurement],
          },
          queryOverrides: {},
          filters: mockFilters,
        });

        expect(mockLoad).toHaveBeenCalledWith(
          expect.objectContaining({
            filters: [
              ...existingFilters,
              {
                member: expectedDimension,
                operator: 'inDateRange',
                values: [
                  pikadayToString(mockFilters.startDate),
                  pikadayToString(mockFilters.endDate),
                ],
              },
            ],
          }),
        );
      },
    );
  });
});
