import { CubejsApi, HttpTransport } from '@cubejs-client/core';
import { convertToSnakeCase } from '~/lib/utils/text_utility';
import { pikadayToString } from '~/lib/utils/datetime_utility';
import csrf from '~/lib/utils/csrf';

// This can be any value because the cube proxy adds the real API token.
const CUBE_API_TOKEN = '1';
const PRODUCT_ANALYTICS_CUBE_PROXY = '/api/v4/projects/:id/product_analytics/request';
const DEFAULT_COUNT_KEY = 'TrackedEvents.count';

// Filter measurement types must be lowercase
export const DATE_RANGE_FILTER_DIMENSIONS = {
  sessions: 'Sessions.startAt',
  trackedevents: 'TrackedEvents.utcTime',
};

const convertToCommonChartFormat = (resultSet) => {
  const seriesNames = resultSet.seriesNames();
  const pivot = resultSet.chartPivot();

  return seriesNames.map((series) => ({
    name: series.title,
    data: pivot.map((p) => [p.x, p[series.key]]),
  }));
};

const getLinkDimensions = (key, visualizationOptions) =>
  visualizationOptions?.links?.find(({ text, href }) => [text, href].includes(key));

const convertToTableFormat = (resultSet, _query, visualizationOptions) => {
  const columns = resultSet.tableColumns();
  const rows = resultSet.tablePivot();

  const columnTitles = Object.fromEntries(
    columns.map((column) => [column.key, convertToSnakeCase(column.shortTitle)]),
  );

  return rows.map((row) => {
    return Object.fromEntries(
      Object.entries(row)
        .map(([key, value]) => {
          const linkDimensions = getLinkDimensions(key, visualizationOptions);

          switch (key) {
            case linkDimensions?.href:
              // Skipped because the href gets rendered as part of the link text.
              return null;
            case linkDimensions?.text:
              return [
                columnTitles[key],
                {
                  text: value,
                  href: row[linkDimensions.href],
                },
              ];
            default:
              return [columnTitles[key], value];
          }
        })
        .filter(Boolean),
    );
  });
};

const convertToSingleValue = (resultSet, query) => {
  const [measure] = query?.measures ?? [];
  const [row] = resultSet.rawData();

  if (!row) {
    return 0;
  }

  return row[measure ?? DEFAULT_COUNT_KEY] ?? Object.values(row)[0] ?? 0;
};

const buildDateRangeFilter = (query, queryOverrides, { startDate, endDate }) => {
  if (!startDate && !endDate) return {};

  const measurement = query.measures[0].split('.')[0].toLowerCase();

  return {
    filters: [
      ...(query.filters ?? []),
      ...(queryOverrides.filters ?? []),
      {
        member: DATE_RANGE_FILTER_DIMENSIONS[measurement],
        operator: 'inDateRange',
        values: [pikadayToString(startDate), pikadayToString(endDate)],
      },
    ],
  };
};

const buildCubeQuery = (query, queryOverrides, filters) => ({
  ...query,
  ...queryOverrides,
  ...buildDateRangeFilter(query, queryOverrides, filters),
});

const VISUALIZATION_PARSERS = {
  LineChart: convertToCommonChartFormat,
  ColumnChart: convertToCommonChartFormat,
  DataTable: convertToTableFormat,
  SingleStat: convertToSingleValue,
};

export const createCubeJsApi = (projectId) =>
  new CubejsApi(CUBE_API_TOKEN, {
    transport: new HttpTransport({
      apiUrl: PRODUCT_ANALYTICS_CUBE_PROXY.replace(':id', projectId),
      method: 'POST',
      headers: {
        [csrf.headerKey]: csrf.token,
        'X-Requested-With': 'XMLHttpRequest',
      },
      credentials: 'same-origin',
    }),
  });

export const fetch = async ({
  projectId,
  visualizationType,
  visualizationOptions,
  query,
  queryOverrides = {},
  filters = {},
}) => {
  const userQuery = buildCubeQuery(query, queryOverrides, filters);
  const resultSet = await createCubeJsApi(projectId).load(userQuery);

  return VISUALIZATION_PARSERS[visualizationType](resultSet, userQuery, visualizationOptions);
};
