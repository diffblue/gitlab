import { stringify } from 'yaml';
import service from '~/ide/services/';
import { s__, sprintf } from '~/locale';

export const DASHBOARD_BRANCH = 'main';
export const CUSTOM_DASHBOARDS_PATH = '.gitlab/analytics/dashboards/';
export const PRODUCT_ANALYTICS_VISUALIZATIONS_PATH = '.gitlab/analytics/dashboards/visualizations/';

export const CONFIGURATION_FILE_TYPE = '.yaml';
export const CREATE_FILE_ACTION = 'create';
export const UPDATE_FILE_ACTION = 'update';

export async function saveProductAnalyticsVisualization(
  visualizationName,
  visualizationCode,
  projectInfo,
) {
  const payload = {
    branch: DASHBOARD_BRANCH,
    commit_message: sprintf(s__('Analytics|Updating visualization %{visualizationName}'), {
      visualizationName,
    }),
    actions: [
      {
        action: CREATE_FILE_ACTION,
        file_path: `${PRODUCT_ANALYTICS_VISUALIZATIONS_PATH}${visualizationName}${CONFIGURATION_FILE_TYPE}`,
        content: stringify(visualizationCode, null),
        encoding: 'text',
      },
    ],
  };
  return service.commit(projectInfo.fullPath, payload);
}

export async function saveCustomDashboard({
  dashboardSlug,
  dashboardConfig,
  projectInfo,
  isNewFile = false,
}) {
  const action = isNewFile ? CREATE_FILE_ACTION : UPDATE_FILE_ACTION;
  const commitText = isNewFile
    ? s__('Analytics|Create dashboard %{dashboardSlug}')
    : s__('Analytics|Updating dashboard %{dashboardSlug}');
  const payload = {
    branch: 'main',
    commit_message: sprintf(commitText, { dashboardSlug }),
    actions: [
      {
        action,
        file_path: `${CUSTOM_DASHBOARDS_PATH}${dashboardSlug}/${dashboardSlug}${CONFIGURATION_FILE_TYPE}`,
        content: stringify(dashboardConfig, null),
        encoding: 'text',
      },
    ],
  };
  return service.commit(projectInfo.fullPath, payload);
}
