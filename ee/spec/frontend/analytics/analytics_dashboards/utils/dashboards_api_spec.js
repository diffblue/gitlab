import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

import service from '~/ide/services/';

import {
  getCustomDashboards,
  getCustomDashboard,
  saveCustomDashboard,
  getProductAnalyticsVisualizationList,
  getProductAnalyticsVisualization,
  saveProductAnalyticsVisualization,
  CUSTOM_DASHBOARDS_PATH,
  PRODUCT_ANALYTICS_VISUALIZATIONS_PATH,
  CREATE_FILE_ACTION,
  UPDATE_FILE_ACTION,
  CONFIGURATION_FILE_TYPE,
  DASHBOARD_BRANCH,
} from 'ee/analytics/analytics_dashboards/api/dashboards_api';
import {
  TEST_CUSTOM_DASHBOARDS_PROJECT,
  TEST_CUSTOM_DASHBOARDS_LIST,
  TEST_CUSTOM_DASHBOARD,
} from '../mock_data';

describe('AnalyticsDashboard', () => {
  const dummyUrlRoot = '/gitlab';
  const dummyRandom = 0.123;

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

  describe('dashboard functions', () => {
    it.each`
      scenario                                            | response                       | expected
      ${'returns all dashboards for array responses'}     | ${TEST_CUSTOM_DASHBOARDS_LIST} | ${TEST_CUSTOM_DASHBOARDS_LIST}
      ${'returns an empty array for non-array responses'} | ${'Not an array'}              | ${[]}
    `('$scenario', async ({ response, expected }) => {
      const expectedUrl = `${dummyUrlRoot}/${
        TEST_CUSTOM_DASHBOARDS_PROJECT.fullPath
      }/-/refs/main/logs_tree/${encodeURIComponent(CUSTOM_DASHBOARDS_PATH.replace(/^\//, ''))}`;

      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, response);
      jest.spyOn(axios, 'get');

      const result = await getCustomDashboards(TEST_CUSTOM_DASHBOARDS_PROJECT);

      expect(result).toStrictEqual(expected);
      expect(axios.get).toHaveBeenCalledWith(expectedUrl, {
        params: { cb: dummyRandom, format: 'json', offset: 0 },
      });
    });

    it('get a single dashboard', async () => {
      const expectedUrl = `${dummyUrlRoot}/${
        TEST_CUSTOM_DASHBOARDS_PROJECT.fullPath
      }/-/raw/main/${encodeURIComponent(
        CUSTOM_DASHBOARDS_PATH + `abc${CONFIGURATION_FILE_TYPE}`.replace(/^\//, ''),
      )}`;

      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, TEST_CUSTOM_DASHBOARD());
      jest.spyOn(axios, 'get');
      await getCustomDashboard('abc', TEST_CUSTOM_DASHBOARDS_PROJECT);
      expect(axios.get).toHaveBeenCalledWith(expectedUrl, {
        params: { cb: dummyRandom },
      });
    });
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
      const dashboardId = 'abc';

      await saveCustomDashboard({
        dashboardId,
        dashboardObject: { id: 'test' },
        projectInfo: TEST_CUSTOM_DASHBOARDS_PROJECT,
        isNewFile,
      });

      const callPayload = {
        branch: DASHBOARD_BRANCH,
        commit_message: isNewFile ? 'Create dashboard abc' : 'Updating dashboard abc',
        actions: [
          {
            action,
            file_path: `${CUSTOM_DASHBOARDS_PATH}${dashboardId}${CONFIGURATION_FILE_TYPE}`,
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

  describe('visualization functions', () => {
    it.each`
      scenario                                            | response                       | expected
      ${'returns all visualizations for array responses'} | ${TEST_CUSTOM_DASHBOARDS_LIST} | ${TEST_CUSTOM_DASHBOARDS_LIST}
      ${'returns an empty array for non-array responses'} | ${'Not an array'}              | ${[]}
    `('$scenario', async ({ response, expected }) => {
      const expectedUrl = `${dummyUrlRoot}/${
        TEST_CUSTOM_DASHBOARDS_PROJECT.fullPath
      }/-/refs/main/logs_tree/${encodeURIComponent(
        PRODUCT_ANALYTICS_VISUALIZATIONS_PATH.replace(/^\//, ''),
      )}`;

      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, response);
      jest.spyOn(axios, 'get');

      const result = await getProductAnalyticsVisualizationList(TEST_CUSTOM_DASHBOARDS_PROJECT);

      expect(result).toStrictEqual(expected);
      expect(axios.get).toHaveBeenCalledWith(expectedUrl, {
        params: { cb: dummyRandom, format: 'json', offset: 0 },
      });
    });

    it('get a single visualization', async () => {
      const expectedUrl = `${dummyUrlRoot}/${
        TEST_CUSTOM_DASHBOARDS_PROJECT.fullPath
      }/-/raw/main/${encodeURIComponent(
        PRODUCT_ANALYTICS_VISUALIZATIONS_PATH + `abc${CONFIGURATION_FILE_TYPE}`.replace(/^\//, ''),
      )}`;

      mock.onGet(expectedUrl).reply(HTTP_STATUS_OK, TEST_CUSTOM_DASHBOARD());
      jest.spyOn(axios, 'get');
      await getProductAnalyticsVisualization('abc', TEST_CUSTOM_DASHBOARDS_PROJECT);
      expect(axios.get).toHaveBeenCalledWith(expectedUrl, {
        params: { cb: dummyRandom },
      });
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
