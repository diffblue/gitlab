import { GlSkeletonLoader, GlEmptyState } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import {
  HTTP_STATUS_CREATED,
  HTTP_STATUS_FORBIDDEN,
  HTTP_STATUS_BAD_REQUEST,
} from '~/lib/utils/http_status';
import { createAlert } from '~/alert';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import getProductAnalyticsDashboardQuery from 'ee/analytics/analytics_dashboards/graphql/queries/get_product_analytics_dashboard.query.graphql';
import getAvailableVisualizations from 'ee/analytics/analytics_dashboards/graphql/queries/get_all_product_analytics_visualizations.query.graphql';
import AnalyticsDashboard from 'ee/analytics/analytics_dashboards/components/analytics_dashboard.vue';
import CustomizableDashboard from 'ee/vue_shared/components/customizable_dashboard/customizable_dashboard.vue';
import {
  buildDefaultDashboardFilters,
  updateApolloCache,
} from 'ee/vue_shared/components/customizable_dashboard/utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import {
  I18N_DASHBOARD_NOT_FOUND_TITLE,
  I18N_DASHBOARD_NOT_FOUND_DESCRIPTION,
  I18N_DASHBOARD_NOT_FOUND_ACTION,
  I18N_DASHBOARD_SAVED_SUCCESSFULLY,
  I18N_DASHBOARD_ERROR_WHILE_SAVING,
  I18N_PRODUCT_ANALYTICS_TITLE,
  NEW_DASHBOARD,
} from 'ee/analytics/analytics_dashboards/constants';
import { saveCustomDashboard } from 'ee/analytics/analytics_dashboards/api/dashboards_api';
import {
  TEST_CUSTOM_DASHBOARDS_PROJECT,
  TEST_EMPTY_DASHBOARD_SVG_PATH,
  TEST_ROUTER_BACK_HREF,
  TEST_DASHBOARD_GRAPHQL_SUCCESS_RESPONSE,
  TEST_DASHBOARD_GRAPHQL_404_RESPONSE,
  TEST_CUSTOM_DASHBOARD_GRAPHQL_SUCCESS_RESPONSE,
  TEST_VISUALIZATIONS_GRAPHQL_SUCCESS_RESPONSE,
} from '../mock_data';

const mockAlertDismiss = jest.fn();
jest.mock('~/alert', () => ({
  createAlert: jest.fn().mockImplementation(() => ({
    dismiss: mockAlertDismiss,
  })),
}));

jest.mock('ee/analytics/analytics_dashboards/api/dashboards_api', () => ({
  saveCustomDashboard: jest.fn(),
}));

jest.mock('ee/vue_shared/components/customizable_dashboard/utils', () => ({
  ...jest.requireActual('ee/vue_shared/components/customizable_dashboard/utils'),
  updateApolloCache: jest.fn(),
}));

const showToast = jest.fn();

Vue.use(VueApollo);

describe('AnalyticsDashboard', () => {
  let wrapper;
  const namespaceId = '1';

  const findDashboard = () => wrapper.findComponent(CustomizableDashboard);
  const findLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  const mockSaveDashboardImplementation = async (responseCallback) => {
    saveCustomDashboard.mockImplementation(responseCallback);

    await waitForPromises();

    findDashboard().vm.$emit('save', 'custom_dashboard', { panels: [] });
  };

  const getFirstParsedDashboard = (dashboards) => {
    const firstDashboard = dashboards.data.project.productAnalyticsDashboards.nodes[0];

    const panels = firstDashboard.panels?.nodes || [];

    return {
      ...firstDashboard,
      panels,
    };
  };

  let mockAnalyticsDashboardsHandler = jest.fn();
  let mockAvailableVisualizationsHandler = jest.fn();

  const mockDashboardResponse = (response) => {
    mockAnalyticsDashboardsHandler = jest.fn().mockResolvedValue(response);
  };
  const mockAvailableVisualizationsResponse = (response) => {
    mockAvailableVisualizationsHandler = jest.fn().mockResolvedValue(response);
  };

  afterEach(() => {
    mockAnalyticsDashboardsHandler = jest.fn();
    mockAvailableVisualizationsHandler = jest.fn();
  });

  const breadcrumbState = { updateName: jest.fn() };

  const createWrapper = ({
    props = {},
    routeSlug = '',
    glFeatures = {
      combinedAnalyticsDashboardsEditor: false,
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
      [getAvailableVisualizations, mockAvailableVisualizationsHandler],
    ]);

    wrapper = shallowMountExtended(AnalyticsDashboard, {
      apolloProvider: mockApollo,
      propsData: {
        ...props,
      },
      stubs: ['router-link', 'router-view'],
      mocks,
      provide: {
        namespaceId,
        customDashboardsProject: TEST_CUSTOM_DASHBOARDS_PROJECT,
        dashboardEmptyStateIllustrationPath: TEST_EMPTY_DASHBOARD_SVG_PATH,
        namespaceFullPath: TEST_CUSTOM_DASHBOARDS_PROJECT.fullPath,
        glFeatures,
        breadcrumbState,
      },
    });
  };

  describe('when mounted', () => {
    beforeEach(() => {
      mockDashboardResponse(TEST_DASHBOARD_GRAPHQL_SUCCESS_RESPONSE);
    });

    it('should render with mock dashboard with filter properties', async () => {
      createWrapper();

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

    it('should render the loading icon while fetching data', async () => {
      createWrapper({
        routeSlug: 'audience',
      });

      expect(findLoader().exists()).toBe(true);

      await waitForPromises();

      expect(findLoader().exists()).toBe(false);
    });

    it('should render dashboard by slug', async () => {
      createWrapper({
        routeSlug: 'audience',
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
      mockDashboardResponse(TEST_DASHBOARD_GRAPHQL_404_RESPONSE);

      createWrapper();

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

  describe('available visualizations', () => {
    const setupDashboard = (dashboardResponse, slug = '') => {
      mockDashboardResponse(dashboardResponse);
      mockAvailableVisualizationsResponse(TEST_VISUALIZATIONS_GRAPHQL_SUCCESS_RESPONSE);

      createWrapper({
        glFeatures: {
          combinedAnalyticsDashboardsEditor: true,
        },
        routeSlug: slug || dashboardResponse.data.project.productAnalyticsDashboards.nodes[0]?.slug,
      });

      return waitForPromises();
    };

    it('fetches the available visualizations when a custom dashboard is loaded', async () => {
      await setupDashboard(TEST_CUSTOM_DASHBOARD_GRAPHQL_SUCCESS_RESPONSE);

      expect(mockAvailableVisualizationsHandler).toHaveBeenCalledWith({
        projectPath: TEST_CUSTOM_DASHBOARDS_PROJECT.fullPath,
      });

      const visualizations =
        TEST_VISUALIZATIONS_GRAPHQL_SUCCESS_RESPONSE.data.project.productAnalyticsVisualizations
          .nodes;

      expect(findDashboard().props().availableVisualizations).toMatchObject({
        [I18N_PRODUCT_ANALYTICS_TITLE]: {
          loading: false,
          visualizations,
        },
      });
    });

    it('fetches the available visualizations from the backend when a dashboard is new', async () => {
      await setupDashboard(TEST_CUSTOM_DASHBOARD_GRAPHQL_SUCCESS_RESPONSE, NEW_DASHBOARD);

      expect(mockAvailableVisualizationsHandler).toHaveBeenCalledWith({
        projectPath: TEST_CUSTOM_DASHBOARDS_PROJECT.fullPath,
      });
    });

    it('does not fetch the available visualizations when a builtin dashboard is loaded it', async () => {
      await setupDashboard(TEST_DASHBOARD_GRAPHQL_SUCCESS_RESPONSE);

      expect(mockAvailableVisualizationsHandler).not.toHaveBeenCalled();
      expect(findDashboard().props().availableVisualizations).toMatchObject({});
    });

    it('does not fetch the available visualizations when a dashboard was not loaded', async () => {
      await setupDashboard(TEST_DASHBOARD_GRAPHQL_404_RESPONSE);

      expect(mockAvailableVisualizationsHandler).not.toHaveBeenCalled();
      expect(findDashboard().exists()).toBe(false);
    });
  });

  describe('with editor disabled', () => {
    describe('when a dashboard is new', () => {
      beforeEach(() => {
        createWrapper({ props: { isNewDashboard: true } });

        return waitForPromises();
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

      it('does not fetch the list of available visualizations', () => {
        expect(mockAvailableVisualizationsHandler).not.toHaveBeenCalled();
      });
    });
  });

  describe('with editor enabled', () => {
    beforeEach(() =>
      mockAvailableVisualizationsResponse(TEST_VISUALIZATIONS_GRAPHQL_SUCCESS_RESPONSE),
    );

    describe('when saving', () => {
      beforeEach(() => mockDashboardResponse(TEST_DASHBOARD_GRAPHQL_SUCCESS_RESPONSE));

      it('custom dashboard successfully by slug', async () => {
        createWrapper({
          routeSlug: 'custom_dashboard',
          glFeatures: { combinedAnalyticsDashboardsEditor: true },
        });

        await mockSaveDashboardImplementation(() => ({ status: HTTP_STATUS_CREATED }));

        expect(saveCustomDashboard).toHaveBeenCalledWith({
          dashboardSlug: 'custom_dashboard',
          dashboardConfig: { panels: [] },
          projectInfo: TEST_CUSTOM_DASHBOARDS_PROJECT,
          isNewFile: false,
        });

        expect(showToast).toHaveBeenCalledWith(I18N_DASHBOARD_SAVED_SUCCESSFULLY);
      });

      describe('dashboard errors', () => {
        beforeEach(() => {
          createWrapper({
            routeSlug: 'custom_dashboard',
            glFeatures: { combinedAnalyticsDashboardsEditor: true },
          });
        });

        it('creates an alert when the response status is HTTP_STATUS_FORBIDDEN', async () => {
          await mockSaveDashboardImplementation(() => ({ status: HTTP_STATUS_FORBIDDEN }));

          expect(createAlert).toHaveBeenCalledWith({
            message: I18N_DASHBOARD_ERROR_WHILE_SAVING,
            captureError: true,
            error: new Error(`Bad save dashboard response. Status:${HTTP_STATUS_FORBIDDEN}`),
          });
        });

        it('creates an alert when the fetch request throws an error', async () => {
          const newError = new Error();
          await mockSaveDashboardImplementation(() => {
            throw newError;
          });

          expect(createAlert).toHaveBeenCalledWith({
            error: newError,
            message: I18N_DASHBOARD_ERROR_WHILE_SAVING,
            captureError: true,
          });
        });

        it('clears the alert when the component is destroyed', async () => {
          await mockSaveDashboardImplementation(() => {
            throw new Error();
          });

          wrapper.destroy();

          await nextTick();

          expect(mockAlertDismiss).toHaveBeenCalled();
        });

        it('clears the alert when the dashboard saved succesfully', async () => {
          await mockSaveDashboardImplementation(() => {
            throw new Error();
          });

          await mockSaveDashboardImplementation(() => ({ status: HTTP_STATUS_CREATED }));

          expect(mockAlertDismiss).toHaveBeenCalled();
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

      it('updates the apollo cache', async () => {
        const slug = 'custom_dashboard';
        createWrapper({
          routeSlug: slug,
          glFeatures: { combinedAnalyticsDashboardsEditor: true },
        });

        await mockSaveDashboardImplementation(() => ({ status: HTTP_STATUS_CREATED }));
        await waitForPromises();

        expect(updateApolloCache).toHaveBeenCalledWith(expect.any(Object), namespaceId, slug, {
          panels: [],
        });
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
          },
          defaultFilters: buildDefaultDashboardFilters(''),
          showDateRangeFilter: true,
          syncUrlFilters: false,
        });
      });

      it('saves the dashboard as a new file', async () => {
        await mockSaveDashboardImplementation(() => ({ status: HTTP_STATUS_CREATED }));

        expect(saveCustomDashboard).toHaveBeenCalledWith({
          dashboardSlug: 'custom_dashboard',
          dashboardConfig: { panels: [] },
          projectInfo: TEST_CUSTOM_DASHBOARDS_PROJECT,
          isNewFile: true,
        });
      });
    });
  });
});
