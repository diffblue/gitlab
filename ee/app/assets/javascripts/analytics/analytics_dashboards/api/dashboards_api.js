import { parse, stringify } from 'yaml';
import axios from '~/lib/utils/axios_utils';
import service from '~/ide/services/';
import { s__, sprintf } from '~/locale';

export const DASHBOARD_BRANCH = 'main';
export const CUSTOM_DASHBOARDS_PATH = '.gitlab/analytics/dashboards/';
export const PRODUCT_ANALYTICS_VISUALIZATIONS_PATH = '.gitlab/analytics/dashboards/visualizations/';

export const CONFIGURATION_FILE_TYPE = '.yaml';
export const CREATE_FILE_ACTION = 'create';
export const UPDATE_FILE_ACTION = 'update';

// The `cb` parameter is added cache-bust, the API responses are cached by default
const getFileListFromCustomDashboardProject = async (path, projectInfo) => {
  const { data } = await axios.get(
    `${gon.relative_url_root}/${
      projectInfo.fullPath
    }/-/refs/${DASHBOARD_BRANCH}/logs_tree/${encodeURIComponent(path.replace(/^\//, ''))}`,
    { params: { format: 'json', offset: 0, cb: Math.random() } },
  );
  return Array.isArray(data) ? data : [];
};

// The `cb` parameter is added cache-bust, the API responses are cached by default
const getFileFromCustomDashboardProject = async (directory, fileId, projectInfo) => {
  const { data } = await axios.get(
    `${gon.relative_url_root}/${
      projectInfo.fullPath
    }/-/raw/${DASHBOARD_BRANCH}/${encodeURIComponent(
      `${directory}${fileId}${CONFIGURATION_FILE_TYPE}`.replace(/^\//, ''),
    )}`,
    { params: { cb: Math.random() } },
  );
  return parse(data);
};

export async function getProductAnalyticsVisualizationList(projectInfo) {
  return getFileListFromCustomDashboardProject(PRODUCT_ANALYTICS_VISUALIZATIONS_PATH, projectInfo);
}

export async function getProductAnalyticsVisualization(visualizationId, projectInfo) {
  return getFileFromCustomDashboardProject(
    PRODUCT_ANALYTICS_VISUALIZATIONS_PATH,
    visualizationId,
    projectInfo,
  );
}

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

export async function getCustomDashboard(dashboardId, projectInfo) {
  return getFileFromCustomDashboardProject(CUSTOM_DASHBOARDS_PATH, dashboardId, projectInfo);
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
