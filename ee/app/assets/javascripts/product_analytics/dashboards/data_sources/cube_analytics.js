import { CubejsApi, HttpTransport } from '@cubejs-client/core';
import { convertToSnakeCase } from '~/lib/utils/text_utility';
import csrf from '~/lib/utils/csrf';

// This can be any value because the cube proxy adds the real API token.
const CUBE_API_TOKEN = '1';

const PRODUCT_ANALYTICS_CUBE_PROXY = '/api/v4/projects/:id/product_analytics/request';

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

const convertToSingleValue = (resultSet) => {
  const [row] = resultSet.rawData();

  if (!row) {
    return null;
  }

  return Object.values(row)[0];
};

const VISUALIZATION_PARSERS = {
  LineChart: convertToLineChartFormat,
  DataTable: convertToTableFormat,
  SingleStat: convertToSingleValue,
};

export const fetch = async ({ projectId, visualizationType, query, queryOverrides = {} }) => {
  const cubejsApi = new CubejsApi(CUBE_API_TOKEN, {
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

  const resultSet = await cubejsApi.load({ ...query, ...queryOverrides });

  return VISUALIZATION_PARSERS[visualizationType](resultSet);
};
