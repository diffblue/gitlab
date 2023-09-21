import produce from 'immer';
import isEmpty from 'lodash/isEmpty';
import uniqueId from 'lodash/uniqueId';
import { TYPENAME_ANALYTICS_DASHBOARD_PANEL } from 'ee/analytics/analytics_dashboards/graphql/constants';
import getProductAnalyticsDashboardQuery from 'ee/analytics/analytics_dashboards/graphql/queries/get_product_analytics_dashboard.query.graphql';
import getAllProductAnalyticsDashboardsQuery from 'ee/analytics/analytics_dashboards/graphql/queries/get_all_product_analytics_dashboards.query.graphql';
import { queryToObject } from '~/lib/utils/url_utility';
import { formatDate, parsePikadayDate } from '~/lib/utils/datetime_utility';
import { ISO_SHORT_FORMAT } from '~/vue_shared/constants';
import {
  convertObjectPropsToCamelCase,
  convertObjectPropsToSnakeCase,
} from '~/lib/utils/common_utils';
import {
  DATE_RANGE_OPTIONS,
  CUSTOM_DATE_RANGE_KEY,
  DEFAULT_SELECTED_OPTION_INDEX,
} from './filters/constants';
import { CATEGORY_SINGLE_STATS, CATEGORY_CHARTS, CATEGORY_TABLES } from './constants';

const isCustomOption = (option) => option && option === CUSTOM_DATE_RANGE_KEY;

export const getDateRangeOption = (optionKey) =>
  DATE_RANGE_OPTIONS.find(({ key }) => key === optionKey);

export const dateRangeOptionToFilter = ({ startDate, endDate, key }) => ({
  startDate,
  endDate,
  dateRangeOption: key,
});

const DEFAULT_FILTER = dateRangeOptionToFilter(DATE_RANGE_OPTIONS[DEFAULT_SELECTED_OPTION_INDEX]);

export const buildDefaultDashboardFilters = (queryString) => {
  const { dateRangeOption: optionKey, startDate, endDate } = convertObjectPropsToCamelCase(
    queryToObject(queryString, { gatherArrays: true }),
  );

  const customDateRange = isCustomOption(optionKey);

  return {
    ...DEFAULT_FILTER,
    // Override default filter with user defined option
    ...(optionKey && dateRangeOptionToFilter(getDateRangeOption(optionKey))),
    // Override date range when selected option is custom date range
    ...(customDateRange && { startDate: parsePikadayDate(startDate) }),
    ...(customDateRange && { endDate: parsePikadayDate(endDate) }),
  };
};

export const filtersToQueryParams = ({ dateRangeOption, startDate, endDate }) => {
  const customDateRange = isCustomOption(dateRangeOption);

  return convertObjectPropsToSnakeCase({
    dateRangeOption,
    // Clear the date range unless the custom date range is selected
    startDate: customDateRange ? formatDate(startDate, ISO_SHORT_FORMAT) : null,
    endDate: customDateRange ? formatDate(endDate, ISO_SHORT_FORMAT) : null,
  });
};

export const isEmptyPanelData = (visualizationType, data) => {
  if (visualizationType === 'SingleStat') {
    // SingleStat visualizations currently do not show an empty state, and instead show a default "0" value
    // This will be revisited: https://gitlab.com/gitlab-org/gitlab/-/issues/398792
    return false;
  }
  return isEmpty(data);
};

/**
 * Validator for the availableVisualizations property
 */
export const availableVisualizationsValidator = ({ loading, visualizations }) => {
  return typeof loading === 'boolean' && Array.isArray(visualizations);
};

/**
 * Get the category key for visualizations by their type. Default is "charts".
 */
export const getVisualizationCategory = (visualization) => {
  if (visualization.type === 'SingleStat') {
    return CATEGORY_SINGLE_STATS;
  }
  if (visualization.type === 'DataTable') {
    return CATEGORY_TABLES;
  }
  return CATEGORY_CHARTS;
};

export const getUniquePanelId = () => uniqueId('panel-');

/**
 * Maps a full hydrated dashboard (including GraphQL __typenames, and full visualization definitions) into a slimmed down version that complies with the dashboard schema definition
 */
export const getDashboardConfig = (hydratedDashboard) => {
  const { __typename: dashboardTypename, userDefined, slug, ...dashboardRest } = hydratedDashboard;
  return {
    ...dashboardRest,
    panels: hydratedDashboard.panels.map((panel) => {
      const { __typename: panelTypename, id, ...panelRest } = panel;
      return {
        ...panelRest,
        visualization: panel.visualization.slug,
      };
    }),
  };
};

/**
 * Updates a dashboard detail in cache from getProductAnalyticsDashboard:{slug}
 */
const updateDashboardDetailsApolloCache = (
  apolloClient,
  dashboard,
  dashboardSlug,
  namespaceFullPath,
) => {
  const getDashboardDetailsQuery = {
    query: getProductAnalyticsDashboardQuery,
    variables: {
      projectPath: namespaceFullPath,
      slug: dashboardSlug,
    },
  };
  const sourceData = apolloClient.readQuery(getDashboardDetailsQuery);
  if (!sourceData) {
    // Dashboard details not yet in cache, must be a new dashboard, nothing to update
    return;
  }

  const data = produce(sourceData, (draftState) => {
    const { nodes } = draftState.project.customizableDashboards;
    const updateIndex = nodes.findIndex(({ slug }) => slug === dashboardSlug);

    if (updateIndex < 0) return;

    const updateNode = nodes[updateIndex];

    nodes.splice(updateIndex, 1, {
      ...updateNode,
      ...dashboard,
      panels: {
        ...updateNode.panels,
        nodes:
          dashboard.panels?.map((panel) => {
            const { id, ...panelRest } = panel;
            return { __typename: TYPENAME_ANALYTICS_DASHBOARD_PANEL, ...panelRest };
          }) || [],
      },
    });
  });

  apolloClient.writeQuery({
    ...getDashboardDetailsQuery,
    data,
  });
};

/**
 * Adds/updates a newly created dashboard to the dashboards list cache from getAllProductAnalyticsDashboards
 */
const updateDashboardsListApolloCache = (
  apolloClient,
  dashboardSlug,
  dashboard,
  namespaceFullPath,
) => {
  const getDashboardListQuery = {
    query: getAllProductAnalyticsDashboardsQuery,
    variables: {
      projectPath: namespaceFullPath,
    },
  };
  const sourceData = apolloClient.readQuery(getDashboardListQuery);
  if (!sourceData) {
    // Dashboard list not yet loaded in cache, nothing to update
    return;
  }

  const data = produce(sourceData, (draftState) => {
    const { panels, ...dashboardWithoutPanels } = dashboard;
    const { nodes } = draftState.project.customizableDashboards;

    const updateIndex = nodes.findIndex(({ slug }) => slug === dashboardSlug);

    // Add new dashboard if it doesn't exist
    if (updateIndex < 0) {
      nodes.push(dashboardWithoutPanels);
      return;
    }

    nodes.splice(updateIndex, 1, {
      ...nodes[updateIndex],
      ...dashboardWithoutPanels,
    });
  });

  apolloClient.writeQuery({
    ...getDashboardListQuery,
    data,
  });
};

export const updateApolloCache = (
  apolloClient,
  projectId,
  dashboardSlug,
  dashboard,
  namespaceFullPath,
) => {
  // TODO: modify to support removing dashboards from cache https://gitlab.com/gitlab-org/gitlab/-/issues/425513
  updateDashboardDetailsApolloCache(apolloClient, dashboard, dashboardSlug, namespaceFullPath);
  updateDashboardsListApolloCache(apolloClient, dashboardSlug, dashboard, namespaceFullPath);
};
