import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';

import service from '~/ide/services/';

import {
  saveCustomDashboard,
  saveProductAnalyticsVisualization,
  CUSTOM_DASHBOARDS_PATH,
  PRODUCT_ANALYTICS_VISUALIZATIONS_PATH,
  CREATE_FILE_ACTION,
  UPDATE_FILE_ACTION,
  CONFIGURATION_FILE_TYPE,
  DASHBOARD_BRANCH,
} from 'ee/analytics/analytics_dashboards/api/dashboards_api';
import { TEST_CUSTOM_DASHBOARDS_PROJECT } from '../mock_data';

describe('AnalyticsDashboard', () => {
  const dummyUrlRoot = '/gitlab';

  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    window.gon = {
      relative_url_root: dummyUrlRoot,
    };
    jest.spyOn(global.Math, 'random').mockReturnValue(0.123);
  });

  afterEach(() => {
    mock.restore();
    jest.spyOn(global.Math, 'random').mockRestore();
  });

  describe('dashboard save functions', () => {
    beforeEach(() => {
      jest.spyOn(service, 'commit').mockResolvedValue({ data: {} });
    });

    it.each`
      isNewFile | action
      ${true}   | ${CREATE_FILE_ACTION}
      ${false}  | ${UPDATE_FILE_ACTION}
    `('$action(s) a dashboard when isNewFile is "$isNewFile"', async ({ isNewFile, action }) => {
      const dashboardSlug = 'abc';

      await saveCustomDashboard({
        dashboardSlug,
        dashboardConfig: { id: 'test' },
        projectInfo: TEST_CUSTOM_DASHBOARDS_PROJECT,
        isNewFile,
      });

      const callPayload = {
        branch: DASHBOARD_BRANCH,
        commit_message: isNewFile ? 'Create dashboard abc' : 'Updating dashboard abc',
        actions: [
          {
            action,
            file_path: `${CUSTOM_DASHBOARDS_PATH}${dashboardSlug}/${dashboardSlug}${CONFIGURATION_FILE_TYPE}`,
            previous_path: undefined,
            content: 'id: test\n',
            encoding: 'text',
            last_commit_id: undefined,
          },
        ],
        start_sha: undefined,
      };

      expect(service.commit).toHaveBeenCalledWith(
        TEST_CUSTOM_DASHBOARDS_PROJECT.fullPath,
        callPayload,
      );
    });
  });

  describe('visualization save functions', () => {
    beforeEach(() => {
      jest.spyOn(service, 'commit').mockResolvedValue({ data: {} });
    });

    it('save a new visualization', async () => {
      const visualizationName = 'abc';

      const result = await saveProductAnalyticsVisualization(
        visualizationName,
        { id: 'test' },
        TEST_CUSTOM_DASHBOARDS_PROJECT,
      );

      const callPayload = {
        branch: DASHBOARD_BRANCH,
        commit_message: 'Updating visualization abc',
        actions: [
          {
            action: 'create',
            file_path: `${PRODUCT_ANALYTICS_VISUALIZATIONS_PATH}${visualizationName}${CONFIGURATION_FILE_TYPE}`,
            content: 'id: test\n',
            encoding: 'text',
          },
        ],
        start_sha: undefined,
      };

      expect(service.commit).toHaveBeenCalledWith(
        TEST_CUSTOM_DASHBOARDS_PROJECT.fullPath,
        callPayload,
      );

      expect(result).toEqual({ data: {} });
    });
  });
});
