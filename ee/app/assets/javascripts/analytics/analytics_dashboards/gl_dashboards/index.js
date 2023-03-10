import productAnalyticsDashboards from './product_analytics';
import productAnalyticsVisualizations from './product_analytics/visualizations';

// TODO: Replace the hardcoded values with API calls in https://gitlab.com/gitlab-org/gitlab/-/issues/382551

export const builtinDashboards = {
  ...productAnalyticsDashboards,
};

export const builtinVisualizations = {
  ...productAnalyticsVisualizations,
};
