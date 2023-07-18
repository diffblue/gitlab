import isEmpty from 'lodash/isEmpty';
import productAnalyticsDashboardFragment from 'ee/analytics/analytics_dashboards/graphql/fragments/product_analytics_dashboard.fragment.graphql';
import {
  TYPENAME_PRODUCT_ANALYTICS_DASHBOARD,
  TYPENAME_PRODUCT_ANALYTICS_DASHBOARD_CONNECTION,
} from 'ee/analytics/analytics_dashboards/graphql/constants';
import { queryToObject } from '~/lib/utils/url_utility';
import { formatDate, parsePikadayDate } from '~/lib/utils/datetime_utility';
import { ISO_SHORT_FORMAT } from '~/vue_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_PROJECT } from '~/graphql_shared/constants';
import {
  convertObjectPropsToCamelCase,
  convertObjectPropsToSnakeCase,
} from '~/lib/utils/common_utils';
import {
  DATE_RANGE_OPTIONS,
  CUSTOM_DATE_RANGE_KEY,
  DEFAULT_SELECTED_OPTION_INDEX,
} from './filters/constants';

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

export const availableVisualizationsValidator = (obj) => {
  return Object.values(obj).every(
    ({ loading, visualizations }) => typeof loading === 'boolean' && Array.isArray(visualizations),
  );
};

/**
 * Maps a full hydrated dashboard (including GraphQL __typenames, and full visualization definitions) into a slimmed down version that complies with the dashboard schema definition
 */
export const getDashboardConfig = (hydratedDashboard) => {
  const { __typename: dashboardTypename, userDefined, slug, ...dashboardRest } = hydratedDashboard;
  return {
    ...dashboardRest,
    panels: hydratedDashboard.panels.map((panel) => {
      const { __typename: panelTypename, ...panelRest } = panel;
      return {
        ...panelRest,
        visualization: panel.visualization.slug,
      };
    }),
  };
};

/**
 * Adds/updates a dashboard detail in cache from getProductAnalyticsDashboard:{slug}
 */
const updateDashboardDetailsApolloCache = (apolloClient, projectRef, dashboardRef, dashboard) => {
  apolloClient.writeFragment({
    id: dashboardRef,
    fragment: productAnalyticsDashboardFragment,
    data: {
      project: { id: projectRef },
      ...dashboard,
      panels: {
        __typename: TYPENAME_PRODUCT_ANALYTICS_DASHBOARD_CONNECTION,
        nodes: dashboard.panels.map((panel) => ({
          ...panel,
        })),
      },
    },
  });
};

/**
 * Links a newly created dashboard to the project in cache from getAllProductAnalyticsDashboards
 */
const updateDashboardsListApolloCache = (apolloClient, projectRef, dashboardRef) => {
  apolloClient.cache.modify({
    id: projectRef,
    fields: {
      productAnalyticsDashboards(existing) {
        // eslint-disable-next-line no-underscore-dangle
        if (existing.nodes.find((existingDashboard) => existingDashboard.__ref === dashboardRef)) {
          return existing;
        }

        return {
          ...existing,
          nodes: [...existing.nodes, { __ref: dashboardRef }],
        };
      },
    },
  });
};

export const updateApolloCache = (apolloClient, projectId, dashboardSlug, dashboard) => {
  const projectRef = apolloClient.cache.identify({
    __typename: TYPENAME_PROJECT,
    id: convertToGraphQLId(TYPENAME_PROJECT, projectId),
  });
  const dashboardRef = apolloClient.cache.identify({
    __typename: TYPENAME_PRODUCT_ANALYTICS_DASHBOARD,
    slug: dashboardSlug,
  });

  updateDashboardDetailsApolloCache(apolloClient, projectRef, dashboardRef, dashboard);
  updateDashboardsListApolloCache(apolloClient, projectRef, dashboardRef);
};
