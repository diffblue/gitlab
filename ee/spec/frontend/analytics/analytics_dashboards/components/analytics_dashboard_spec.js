import { GlLoadingIcon, GlEmptyState } from '@gitlab/ui';
import {
  HTTP_STATUS_CREATED,
  HTTP_STATUS_FORBIDDEN,
  HTTP_STATUS_NOT_FOUND,
  HTTP_STATUS_BAD_REQUEST,
} from '~/lib/utils/http_status';
import { createAlert } from '~/alert';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import AnalyticsDashboard from 'ee/analytics/analytics_dashboards/components/analytics_dashboard.vue';
import CustomizableDashboard from 'ee/vue_shared/components/customizable_dashboard/customizable_dashboard.vue';
import { dashboard } from 'ee_jest/vue_shared/components/customizable_dashboard/mock_data';
import { buildDefaultDashboardFilters } from 'ee/vue_shared/components/customizable_dashboard/utils';
import {
  I18N_DASHBOARD_NOT_FOUND_TITLE,
  I18N_DASHBOARD_NOT_FOUND_DESCRIPTION,
  I18N_DASHBOARD_NOT_FOUND_ACTION,
  I18N_DASHBOARD_SAVED_SUCCESSFULLY,
  I18N_DASHBOARD_ERROR_WHILE_SAVING,
  NEW_DASHBOARD,
} from 'ee/analytics/analytics_dashboards/constants';
import {
  getCustomDashboard,
  getProductAnalyticsVisualizationList,
  getProductAnalyticsVisualization,
  saveCustomDashboard,
} from 'ee/analytics/analytics_dashboards/api/dashboards_api';
import {
  TEST_CUSTOM_DASHBOARDS_PROJECT,
  TEST_CUSTOM_DASHBOARD,
  TEST_EMPTY_DASHBOARD_SVG_PATH,
  TEST_ROUTER_BACK_HREF,
} from '../mock_data';

jest.mock('~/alert');
jest.mock('ee/analytics/analytics_dashboards/api/dashboards_api');

const showToast = jest.fn();

describe('AnalyticsDashboard', () => {
  let wrapper;

  const findDashboard = () => wrapper.findComponent(CustomizableDashboard);
  const findLoader = () => wrapper.findComponent(GlLoadingIcon);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  const mockSaveDashboardImplementation = async (responseCallback) => {
    saveCustomDashboard.mockImplementation(responseCallback);

    await waitForPromises();

    findDashboard().vm.$emit('save', 'custom_dashboard', {});
  };

  beforeEach(() => {
    getCustomDashboard.mockImplementation(() => TEST_CUSTOM_DASHBOARD);
    getProductAnalyticsVisualizationList.mockImplementation(() => []);
    getProductAnalyticsVisualization.mockImplementation(() => TEST_CUSTOM_DASHBOARD);
  });

  const createWrapper = ({ props = {}, data = {}, routeId = '' } = {}) => {
    const mocks = {
      $toast: {
        show: showToast,
      },
      $route: {
        params: {
          id: routeId,
        },
      },
      $router: {
        replace() {},
        push() {},
        resolve: () => ({ href: TEST_ROUTER_BACK_HREF }),
      },
    };

    wrapper = shallowMountExtended(AnalyticsDashboard, {
      data() {
        return {
          dashboard: null,
          ...data,
        };
      },
      propsData: {
        ...props,
      },
      stubs: ['router-link', 'router-view'],
      mocks,
      provide: {
        customDashboardsProject: TEST_CUSTOM_DASHBOARDS_PROJECT,
        dashboardEmptyStateIllustrationPath: TEST_EMPTY_DASHBOARD_SVG_PATH,
      },
    });
  };

  describe('when mounted', () => {
    it('should render with mock dashboard with filter properties', () => {
      createWrapper({ data: { dashboard } });

      expect(getCustomDashboard).toHaveBeenCalledWith('', TEST_CUSTOM_DASHBOARDS_PROJECT);

      expect(findDashboard().props()).toMatchObject({
        initialDashboard: dashboard,
        defaultFilters: buildDefaultDashboardFilters(''),
        dateRangeLimit: 0,
        showDateRangeFilter: true,
        syncUrlFilters: true,
      });
    });

    it('should render the loading icon while fetching data', async () => {
      createWrapper({ routeId: 'dashboard_audience' });

      expect(findLoader().exists()).toBe(true);

      await waitForPromises();

      expect(findLoader().exists()).toBe(false);
    });

    it('should render audience dashboard by id', async () => {
      createWrapper({ routeId: 'dashboard_audience' });

      await waitForPromises();

      expect(getCustomDashboard).toHaveBeenCalledTimes(0);
      expect(getProductAnalyticsVisualizationList).toHaveBeenCalledWith(
        TEST_CUSTOM_DASHBOARDS_PROJECT,
      );
      expect(getProductAnalyticsVisualization).toHaveBeenCalledTimes(0);

      expect(findDashboard().exists()).toBe(true);
    });

    it('should render behavior dashboard by id', async () => {
      createWrapper({ routeId: 'dashboard_behavior' });

      await waitForPromises();

      expect(getCustomDashboard).toHaveBeenCalledTimes(0);
      expect(getProductAnalyticsVisualizationList).toHaveBeenCalledWith(
        TEST_CUSTOM_DASHBOARDS_PROJECT,
      );
      expect(getProductAnalyticsVisualization).toHaveBeenCalledTimes(0);

      expect(findDashboard().exists()).toBe(true);
    });

    it('should render custom dashboard by id', async () => {
      createWrapper({ routeId: 'custom_dashboard' });

      await waitForPromises();

      expect(getCustomDashboard).toHaveBeenCalledWith(
        'custom_dashboard',
        TEST_CUSTOM_DASHBOARDS_PROJECT,
      );
      expect(getProductAnalyticsVisualizationList).toHaveBeenCalledWith(
        TEST_CUSTOM_DASHBOARDS_PROJECT,
      );
      expect(getProductAnalyticsVisualization).toHaveBeenCalledWith(
        'page_views_per_day',
        TEST_CUSTOM_DASHBOARDS_PROJECT,
      );

      expect(findDashboard().exists()).toBe(true);
    });
  });

  describe('when saving', () => {
    it('custom dashboard successfully by id', async () => {
      createWrapper({ routeId: 'custom_dashboard' });

      await mockSaveDashboardImplementation(() => ({ status: HTTP_STATUS_CREATED }));

      expect(saveCustomDashboard).toHaveBeenCalledWith({
        dashboardId: 'custom_dashboard',
        dashboardObject: {},
        projectInfo: TEST_CUSTOM_DASHBOARDS_PROJECT,
        isNewFile: false,
      });

      await waitForPromises();

      expect(showToast).toHaveBeenCalledWith(I18N_DASHBOARD_SAVED_SUCCESSFULLY);
    });

    it('custom dashboard with an error', async () => {
      createWrapper({ routeId: 'custom_dashboard' });

      await mockSaveDashboardImplementation(() => ({ status: HTTP_STATUS_FORBIDDEN }));

      await waitForPromises();
      expect(createAlert).toHaveBeenCalledWith({
        message: I18N_DASHBOARD_ERROR_WHILE_SAVING,
        captureError: true,
        error: new Error(`Bad save dashboard response. Status:${HTTP_STATUS_FORBIDDEN}`),
      });
    });

    it('custom dashboard with an error thrown', async () => {
      createWrapper({ routeId: 'custom_dashboard' });

      const newError = new Error();

      mockSaveDashboardImplementation(() => {
        throw newError;
      });

      await waitForPromises();
      expect(createAlert).toHaveBeenCalledWith({
        error: newError,
        message: I18N_DASHBOARD_ERROR_WHILE_SAVING,
        captureError: true,
      });
    });

    it('renders an alert with the server message when a bad request was made', async () => {
      createWrapper({ routeId: 'custom_dashboard' });

      const message = 'File already exists';
      const badRequestError = new Error();

      badRequestError.response = {
        status: HTTP_STATUS_BAD_REQUEST,
        data: { message },
      };

      await mockSaveDashboardImplementation(() => {
        throw badRequestError;
      });

      await waitForPromises();
      expect(createAlert).toHaveBeenCalledWith({ message });
    });
  });

  describe('when a custom dashboard cannot be found', () => {
    beforeEach(() => {
      getCustomDashboard.mockRejectedValue({ response: { status: HTTP_STATUS_NOT_FOUND } });
      createWrapper();
      return waitForPromises();
    });

    it('does not render the dashboard or loader', () => {
      expect(findDashboard().exists()).toBe(false);
      expect(findLoader().exists()).toBe(false);
    });

    it('renders the empty state', () => {
      expect(findEmptyState().props()).toMatchObject({
        svgPath: TEST_EMPTY_DASHBOARD_SVG_PATH,
        title: I18N_DASHBOARD_NOT_FOUND_TITLE,
        description: I18N_DASHBOARD_NOT_FOUND_DESCRIPTION,
        primaryButtonText: I18N_DASHBOARD_NOT_FOUND_ACTION,
        primaryButtonLink: TEST_ROUTER_BACK_HREF,
      });
    });
  });

  describe('when a dashboard is new', () => {
    beforeEach(() => {
      createWrapper({ props: { isNewDashboard: true } });
    });

    it('creates a new dashboard and disables the filters', () => {
      expect(findDashboard().props()).toMatchObject({
        initialDashboard: {
          ...NEW_DASHBOARD,
          default: { ...NEW_DASHBOARD },
        },
        defaultFilters: {},
        showDateRangeFilter: false,
        syncUrlFilters: false,
      });
    });

    it('saves the dashboard as a new file', async () => {
      await mockSaveDashboardImplementation(() => ({ status: HTTP_STATUS_CREATED }));

      expect(saveCustomDashboard).toHaveBeenCalledWith({
        dashboardId: 'custom_dashboard',
        dashboardObject: {},
        projectInfo: TEST_CUSTOM_DASHBOARDS_PROJECT,
        isNewFile: true,
      });
    });
  });
});
