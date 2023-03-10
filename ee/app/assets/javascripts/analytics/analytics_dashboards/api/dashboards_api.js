import { parse, stringify } from 'yaml';
import axios from '~/lib/utils/axios_utils';
import service from '~/ide/services/';
import { s__, sprintf } from '~/locale';

const DASHBOARD_BRANCH = 'main';
export const CUSTOM_DASHBOARDS_PATH = '.gitlab/dashboards/';
export const PRODUCT_ANALYTICS_VISUALIZATIONS_PATH =
  '.gitlab/dashboards/product_analytics/visualizations/';

const CREATE_FILE_ACTION = 'create';
const UPDATE_FILE_ACTION = 'update';

// The `cb` parameter is added cache-bust, the API responses are cached by default
const getFileListFromCustomDashboardProject = async (path, projectInfo) => {
  const { data } = await axios.get(
    `${gon.relative_url_root}/${
      projectInfo.fullPath
    }/-/refs/${DASHBOARD_BRANCH}/logs_tree/${encodeURIComponent(path.replace(/^\//, ''))}`,
    { params: { format: 'json', offset: 0, cb: Math.random() } },
  );
  return data;
};

// The `cb` parameter is added cache-bust, the API responses are cached by default
const getFileFromCustomDashboardProject = async (directory, fileId, projectInfo) => {
  const { data } = await axios.get(
    `${gon.relative_url_root}/${
      projectInfo.fullPath
    }/-/raw/${DASHBOARD_BRANCH}/${encodeURIComponent(
      `${directory}${fileId}.yml`.replace(/^\//, ''),
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

export async function getCustomDashboards(projectInfo) {
  return getFileListFromCustomDashboardProject(CUSTOM_DASHBOARDS_PATH, projectInfo);
}

export async function getCustomDashboard(dashboardId, projectInfo) {
  return getFileFromCustomDashboardProject(CUSTOM_DASHBOARDS_PATH, dashboardId, projectInfo);
}

export async function saveCustomDashboard(dashboardId, dashboardObject, projectInfo) {
  const { isNew, ...rest } = dashboardObject;
  const action = isNew ? CREATE_FILE_ACTION : UPDATE_FILE_ACTION;
  const payload = {
    branch: 'main',
    commit_message: sprintf(s__('Analytics|Updating dashboard %{dashboardId}'), {
      dashboardId,
    }),
    actions: [
      {
        action,
        file_path: `${CUSTOM_DASHBOARDS_PATH}${dashboardId}.yml`,
        content: stringify(rest, null),
        encoding: 'text',
      },
    ],
  };
  return service.commit(projectInfo.fullPath, payload);
}
