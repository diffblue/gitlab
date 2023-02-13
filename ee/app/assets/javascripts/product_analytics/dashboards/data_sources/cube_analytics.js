import { CubejsApi, HttpTransport } from '@cubejs-client/core';
import { convertToSnakeCase } from '~/lib/utils/text_utility';
import { pikadayToString } from '~/lib/utils/datetime_utility';
import csrf from '~/lib/utils/csrf';

// This can be any value because the cube proxy adds the real API token.
const CUBE_API_TOKEN = '1';
const PRODUCT_ANALYTICS_CUBE_PROXY = '/api/v4/projects/:id/product_analytics/request';
const DEFAULT_COUNT_KEY = 'TrackedEvents.count';
// Filter measurement types must be lowercase
const FILTER_DIMENSIONS = {
  sessions: 'Sessions.startAt',
  trackedevents: 'TrackedEvents.utcTime',
};

const convertToLineChartFormat = (resultSet) => {
  const seriesNames = resultSet.seriesNames();
  const pivot = resultSet.chartPivot();

  return seriesNames.map((series) => ({
    name: series.title,
    data: pivot.map((p) => [p.x, p[series.key]]),
  }));
};

const convertToTableFormat = (resultSet) => {
  const columns = resultSet.tableColumns();
  const rows = resultSet.tablePivot();

  const columnTitles = Object.fromEntries(
    columns.map((column) => [column.key, convertToSnakeCase(column.shortTitle)]),
  );

  return rows.map((row) => {
    return Object.fromEntries(
      Object.entries(row).map(([key, value]) => [columnTitles[key], value]),
    );
  });
};

const convertToSingleValue = (resultSet, query) => {
  const [measure] = query?.measures ?? [];
  const [row] = resultSet.rawData();

  if (!row) {
    return undefined;
  }

  return row[measure ?? DEFAULT_COUNT_KEY] ?? Object.values(row)[0];
};

const filterByDateRange = (query, queryOverrides, dateRange) => {
  const measurement = query.measures[0].split('.')[0].toLowerCase();
  return {
    filters: [
      ...(query.filters ?? []),
      ...(queryOverrides.filters ?? []),
      {
        member: FILTER_DIMENSIONS[measurement],
        operator: 'inDateRange',
        values: [pikadayToString(dateRange.startDate), pikadayToString(dateRange.endDate)],
      },
    ],
  };
};

const buildCubeQuery = (query, queryOverrides, filters) => ({
  ...query,
  ...queryOverrides,
  ...(filters.dateRange && filterByDateRange(query, queryOverrides, filters.dateRange)),
});

const VISUALIZATION_PARSERS = {
  LineChart: convertToLineChartFormat,
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
  query,
  queryOverrides = {},
  filters = {},
}) => {
  const userQuery = buildCubeQuery(query, queryOverrides, filters);
  const resultSet = await createCubeJsApi(projectId).load(userQuery);

  return VISUALIZATION_PARSERS[visualizationType](resultSet, userQuery);
};

export const NO_DATABASE_ERROR_MESSAGE = '404 Clickhouse Database Not Found';

export const hasAnalyticsData = async (projectId) => {
  try {
    const data = await createCubeJsApi(projectId).load({ measures: [DEFAULT_COUNT_KEY] });

    return data.rawData()[0][DEFAULT_COUNT_KEY] > 0;
  } catch (error) {
    const errorMessage = error?.response?.message;

    // We expect this error to occur when onboarding
    if (errorMessage === NO_DATABASE_ERROR_MESSAGE) {
      return false;
    }

    throw error;
  }
};
