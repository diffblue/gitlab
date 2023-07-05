import { GlLoadingIcon, GlEmptyState } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import {
  HTTP_STATUS_CREATED,
  HTTP_STATUS_FORBIDDEN,
  HTTP_STATUS_NOT_FOUND,
  HTTP_STATUS_BAD_REQUEST,
} from '~/lib/utils/http_status';
import { createAlert } from '~/alert';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import getProductAnalyticsDashboardQuery from 'ee/analytics/analytics_dashboards/graphql/queries/get_product_analytics_dashboard.query.graphql';
import AnalyticsDashboard from 'ee/analytics/analytics_dashboards/components/analytics_dashboard.vue';
import CustomizableDashboard from 'ee/vue_shared/components/customizable_dashboard/customizable_dashboard.vue';
import { dashboard } from 'ee_jest/vue_shared/components/customizable_dashboard/mock_data';
import { buildDefaultDashboardFilters } from 'ee/vue_shared/components/customizable_dashboard/utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import {
  getNextPanelId,
  createNewVisualizationPanel,
} from 'ee/analytics/analytics_dashboards/utils';
import {
  I18N_DASHBOARD_NOT_FOUND_TITLE,
  I18N_DASHBOARD_NOT_FOUND_DESCRIPTION,
  I18N_DASHBOARD_NOT_FOUND_ACTION,
  I18N_DASHBOARD_SAVED_SUCCESSFULLY,
  I18N_DASHBOARD_ERROR_WHILE_SAVING,
  I18N_PRODUCT_ANALYTICS_TITLE,
  NEW_DASHBOARD,
} from 'ee/analytics/analytics_dashboards/constants';
import {
  getCustomDashboard,
  getProductAnalyticsVisualizationList,
  getProductAnalyticsVisualization,
  saveCustomDashboard,
} from 'ee/analytics/analytics_dashboards/api/dashboards_api';
import { builtinVisualizations } from 'ee/analytics/analytics_dashboards/gl_dashboards';
import {
  TEST_CUSTOM_DASHBOARDS_PROJECT,
  TEST_CUSTOM_DASHBOARD,
  TEST_VISUALIZATION,
  TEST_EMPTY_DASHBOARD_SVG_PATH,
  TEST_ROUTER_BACK_HREF,
  TEST_DASHBOARD_GRAPHQL_SUCCESS_RESPONSE,
  TEST_DASHBOARD_GRAPHQL_404_RESPONSE,
} from '../mock_data';

jest.mock('~/alert');
jest.mock('ee/analytics/analytics_dashboards/api/dashboards_api', () => ({
  getProductAnalyticsVisualizationList: jest.fn(),
  getProductAnalyticsVisualization: jest.fn(),
  getCustomDashboard: jest.fn(),
  saveCustomDashboard: jest.fn(),
}));

const showToast = jest.fn();

Vue.use(VueApollo);

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

  const getFirstParsedDashboard = (dashboards) => {
    const firstDashboard = dashboards.data.project.productAnalyticsDashboards.nodes[0];

    const panels = firstDashboard.panels?.nodes || [];

    return {
      ...firstDashboard,
      panels,
      default: { ...firstDashboard, panels },
    };
  };

  let mockAnalyticsDashboardsHandler = jest.fn();

  beforeEach(() => {
    getCustomDashboard.mockImplementation(() => TEST_CUSTOM_DASHBOARD());
    getProductAnalyticsVisualizationList.mockImplementation(() => []);
    getProductAnalyticsVisualization.mockImplementation(() => TEST_VISUALIZATION());
  });

  afterEach(() => {
    mockAnalyticsDashboardsHandler.mockReset();
  });

  const breadcrumbState = { updateName: jest.fn() };

  const createWrapper = ({
    props = {},
    data = {},
    routeSlug = '',
    glFeatures = {
      combinedAnalyticsDashboardsEditor: false,
      productAnalyticsSnowplowSupport: false,
    },
  } = {}) => {
    const mocks = {
      $toast: {
        show: showToast,
      },
      $route: {
        params: {
          slug: routeSlug,
        },
      },
      $router: {
        replace() {},
        push() {},
        resolve: () => ({ href: TEST_ROUTER_BACK_HREF }),
      },
    };

    const mockApollo = createMockApollo([
      [getProductAnalyticsDashboardQuery, mockAnalyticsDashboardsHandler],
    ]);

    wrapper = shallowMountExtended(AnalyticsDashboard, {
      apolloProvider: mockApollo,
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
        projectFullPath: TEST_CUSTOM_DASHBOARDS_PROJECT.fullPath,
        glFeatures,
        breadcrumbState,
      },
    });
  };

  describe('with snowplow disabled', () => {
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

      it('fetches the available visualizations', async () => {
        createWrapper();

        await waitForPromises();

        expect(findDashboard().props().availableVisualizations).toMatchObject({
          [I18N_PRODUCT_ANALYTICS_TITLE]: {
            loading: false,
            visualizationIds: Object.keys(builtinVisualizations),
          },
        });
      });

      it('should render the loading icon while fetching data', async () => {
        createWrapper({ routeSlug: 'audience' });

        expect(findLoader().exists()).toBe(true);

        await waitForPromises();

        expect(findLoader().exists()).toBe(false);
      });

      it('should render audience dashboard by slug', async () => {
        createWrapper({ routeSlug: 'audience' });

        await waitForPromises();

        expect(getCustomDashboard).toHaveBeenCalledTimes(0);
        expect(getProductAnalyticsVisualizationList).toHaveBeenCalledWith(
          TEST_CUSTOM_DASHBOARDS_PROJECT,
        );
        expect(getProductAnalyticsVisualization).toHaveBeenCalledTimes(0);

        expect(findDashboard().exists()).toBe(true);
      });

      it('should render behavior dashboard by slug', async () => {
        createWrapper({ routeSlug: 'behavior' });

        await waitForPromises();

        expect(getCustomDashboard).toHaveBeenCalledTimes(0);
        expect(getProductAnalyticsVisualizationList).toHaveBeenCalledWith(
          TEST_CUSTOM_DASHBOARDS_PROJECT,
        );
        expect(getProductAnalyticsVisualization).toHaveBeenCalledTimes(0);

        expect(findDashboard().exists()).toBe(true);
      });

      it('should render custom dashboard by slug', async () => {
        createWrapper({ routeSlug: 'custom_dashboard' });

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
  });

  describe('with snowplow enabled', () => {
    describe('when mounted', () => {
      beforeEach(() => {
        mockAnalyticsDashboardsHandler = jest
          .fn()
          .mockResolvedValue(TEST_DASHBOARD_GRAPHQL_SUCCESS_RESPONSE);
      });

      it('should render with mock dashboard with filter properties', async () => {
        createWrapper({
          glFeatures: { productAnalyticsSnowplowSupport: true },
        });

        await waitForPromises();

        expect(mockAnalyticsDashboardsHandler).toHaveBeenCalledWith({
          projectPath: TEST_CUSTOM_DASHBOARDS_PROJECT.fullPath,
          slug: '',
        });

        expect(findDashboard().props()).toMatchObject({
          initialDashboard: getFirstParsedDashboard(TEST_DASHBOARD_GRAPHQL_SUCCESS_RESPONSE),
          defaultFilters: buildDefaultDashboardFilters(''),
          dateRangeLimit: 0,
          showDateRangeFilter: true,
          syncUrlFilters: true,
        });

        expect(breadcrumbState.updateName).toHaveBeenCalledWith('Audience');
      });

      it('does not fetch the available visualizations', async () => {
        createWrapper({ glFeatures: { productAnalyticsSnowplowSupport: true } });

        await waitForPromises();

        expect(findDashboard().props().availableVisualizations).toMatchObject({});
      });

      it('should render the loading icon while fetching data', async () => {
        createWrapper({
          routeSlug: 'audience',
          glFeatures: { productAnalyticsSnowplowSupport: true },
        });

        expect(findLoader().exists()).toBe(true);

        await waitForPromises();

        expect(findLoader().exists()).toBe(false);
      });

      it('should render dashboard by slug', async () => {
        createWrapper({
          routeSlug: 'audience',
          glFeatures: { productAnalyticsSnowplowSupport: true },
        });

        await waitForPromises();

        expect(mockAnalyticsDashboardsHandler).toHaveBeenCalledWith({
          projectPath: TEST_CUSTOM_DASHBOARDS_PROJECT.fullPath,
          slug: 'audience',
        });

        expect(breadcrumbState.updateName).toHaveBeenCalledWith('Audience');

        expect(findDashboard().exists()).toBe(true);
      });
    });

    describe('when a custom dashboard cannot be found', () => {
      beforeEach(() => {
        mockAnalyticsDashboardsHandler = jest
          .fn()
          .mockResolvedValue(TEST_DASHBOARD_GRAPHQL_404_RESPONSE);

        createWrapper({ glFeatures: { productAnalyticsSnowplowSupport: true } });

        return waitForPromises();
      });

      it('does not render the dashboard or loader', () => {
        expect(findDashboard().exists()).toBe(false);
        expect(findLoader().exists()).toBe(false);
        expect(breadcrumbState.updateName).toHaveBeenCalledWith('');
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
  });

  describe('when an "add panel" event is received', () => {
    let newPanel;
    const originalPanels = TEST_CUSTOM_DASHBOARD().panels;

    beforeEach(async () => {
      createWrapper({
        routeSlug: 'custom_dashboard',
      });
      await waitForPromises();

      findDashboard().vm.$emit('add-panel', 'foo', 'yml');
      await waitForPromises();

      newPanel = createNewVisualizationPanel(getNextPanelId(originalPanels), 'foo', 'yml');
    });

    it('adds a new panel to the default dashboard object', () => {
      const defaultPanels = findDashboard().props().initialDashboard.default.panels;

      expect(defaultPanels).toHaveLength(originalPanels.length + 1);
      expect(defaultPanels.pop()).toMatchObject(newPanel);
    });

    it('adds a new hydrated panel to the dashboard panels array', () => {
      const { panels } = findDashboard().props().initialDashboard;

      expect(panels).toHaveLength(originalPanels.length + 1);
      expect(panels.pop()).toMatchObject({
        ...newPanel,
        visualization: TEST_VISUALIZATION(),
      });
    });
  });

  describe('when saving', () => {
    it('custom dashboard successfully by slug', async () => {
      createWrapper({ routeSlug: 'custom_dashboard' });

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
      createWrapper({ routeSlug: 'custom_dashboard' });

      await mockSaveDashboardImplementation(() => ({ status: HTTP_STATUS_FORBIDDEN }));

      await waitForPromises();
      expect(createAlert).toHaveBeenCalledWith({
        message: I18N_DASHBOARD_ERROR_WHILE_SAVING,
        captureError: true,
        error: new Error(`Bad save dashboard response. Status:${HTTP_STATUS_FORBIDDEN}`),
      });
    });

    it('custom dashboard with an error thrown', async () => {
      createWrapper({ routeSlug: 'custom_dashboard' });

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
      createWrapper({ routeSlug: 'custom_dashboard' });

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

  describe('with editor disabled', () => {
    describe('when a dashboard is new', () => {
      beforeEach(() => {
        createWrapper({ props: { isNewDashboard: true } });
      });

      it('renders the empty state', async () => {
        await waitForPromises();

        expect(findEmptyState().props()).toMatchObject({
          svgPath: TEST_EMPTY_DASHBOARD_SVG_PATH,
          title: I18N_DASHBOARD_NOT_FOUND_TITLE,
          description: I18N_DASHBOARD_NOT_FOUND_DESCRIPTION,
          primaryButtonText: I18N_DASHBOARD_NOT_FOUND_ACTION,
          primaryButtonLink: TEST_ROUTER_BACK_HREF,
        });
      });
    });
  });

  describe('with editor enabled', () => {
    describe('when saving', () => {
      it('custom dashboard successfully by slug', async () => {
        createWrapper({
          routeSlug: 'custom_dashboard',
          glFeatures: { combinedAnalyticsDashboardsEditor: true },
        });

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
        createWrapper({
          routeSlug: 'custom_dashboard',
          glFeatures: { combinedAnalyticsDashboardsEditor: true },
        });

        await mockSaveDashboardImplementation(() => ({ status: HTTP_STATUS_FORBIDDEN }));

        await waitForPromises();
        expect(createAlert).toHaveBeenCalledWith({
          message: I18N_DASHBOARD_ERROR_WHILE_SAVING,
          captureError: true,
          error: new Error(`Bad save dashboard response. Status:${HTTP_STATUS_FORBIDDEN}`),
        });
      });

      it('custom dashboard with an error thrown', async () => {
        createWrapper({
          routeSlug: 'custom_dashboard',
          glFeatures: { combinedAnalyticsDashboardsEditor: true },
        });

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
        createWrapper({
          routeSlug: 'custom_dashboard',
          glFeatures: { combinedAnalyticsDashboardsEditor: true },
        });

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

    describe('when a dashboard is new', () => {
      beforeEach(() => {
        createWrapper({
          props: { isNewDashboard: true },
          glFeatures: { combinedAnalyticsDashboardsEditor: true },
        });
      });

      it('creates a new dashboard and and disables the filter syncing', async () => {
        await waitForPromises();

        expect(findDashboard().props()).toMatchObject({
          initialDashboard: {
            ...NEW_DASHBOARD,
            default: { ...NEW_DASHBOARD },
          },
          defaultFilters: {},
          showDateRangeFilter: true,
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
});
