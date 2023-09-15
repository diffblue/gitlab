import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert, GlSkeletonLoader } from '@gitlab/ui';
import { mockTracking } from 'helpers/tracking_helper';
import ProductAnalyticsOnboarding from 'ee/product_analytics/onboarding/components/onboarding_list_item.vue';
import DashboardsList from 'ee/analytics/analytics_dashboards/components/dashboards_list.vue';
import DashboardListItem from 'ee/analytics/analytics_dashboards/components/list/dashboard_list_item.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { VALUE_STREAMS_DASHBOARD_CONFIG } from 'ee/analytics/dashboards/constants';
import { InternalEvents } from '~/tracking';
import { helpPagePath } from '~/helpers/help_page_helper';
import { createAlert } from '~/alert';
import getAllProductAnalyticsDashboardsQuery from 'ee/analytics/analytics_dashboards/graphql/queries/get_all_product_analytics_dashboards.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  TEST_COLLECTOR_HOST,
  TEST_TRACKING_KEY,
  TEST_CUSTOM_DASHBOARDS_PROJECT,
  TEST_ALL_DASHBOARDS_GRAPHQL_SUCCESS_RESPONSE,
} from '../mock_data';

const mockAlertDismiss = jest.fn();
jest.mock('~/alert', () => ({
  createAlert: jest.fn().mockImplementation(() => ({
    dismiss: mockAlertDismiss,
  })),
}));

Vue.use(VueApollo);

describe('DashboardsList', () => {
  let wrapper;
  let trackingSpy;

  const findListItems = () => wrapper.findAllComponents(DashboardListItem);
  const findListLoadingSkeletons = () => wrapper.findAllComponents(GlSkeletonLoader);
  const findProductAnalyticsOnboarding = () => wrapper.findComponent(ProductAnalyticsOnboarding);
  const findPageTitle = () => wrapper.findByTestId('title');
  const findPageDescription = () => wrapper.findByTestId('description');
  const findHelpLink = () => wrapper.findByTestId('help-link');
  const findNewDashboardButton = () => wrapper.findByTestId('new-dashboard-button');
  const findVisualizationDesignerButton = () =>
    wrapper.findByTestId('visualization-designer-button');
  const findConfigureAlert = () => wrapper.findComponent(GlAlert);

  const $router = {
    push: jest.fn(),
  };

  let mockAnalyticsDashboardsHandler = jest.fn();

  const createWrapper = (provided = {}) => {
    trackingSpy = mockTracking(undefined, window.document, jest.spyOn);

    const mockApollo = createMockApollo([
      [getAllProductAnalyticsDashboardsQuery, mockAnalyticsDashboardsHandler],
    ]);

    wrapper = shallowMountExtended(DashboardsList, {
      apolloProvider: mockApollo,
      stubs: {
        RouterLink: true,
      },
      mocks: {
        $router,
      },
      provide: {
        isProject: true,
        collectorHost: TEST_COLLECTOR_HOST,
        trackingKey: TEST_TRACKING_KEY,
        customDashboardsProject: TEST_CUSTOM_DASHBOARDS_PROJECT,
        canConfigureDashboardsProject: true,
        namespaceFullPath: TEST_CUSTOM_DASHBOARDS_PROJECT.fullPath,
        analyticsSettingsPath: '/test/-/settings#foo',
        ...provided,
      },
    });
  };

  afterEach(() => {
    mockAnalyticsDashboardsHandler.mockReset();
  });

  describe('by default', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should render the page title', () => {
      expect(findPageTitle().text()).toBe('Analytics dashboards');
    });

    it('does not render the visualization designer button', () => {
      expect(findVisualizationDesignerButton().exists()).toBe(false);
    });

    it('does not render the new dashboard button', () => {
      expect(findNewDashboardButton().exists()).toBe(false);
    });

    it('should render the help link', () => {
      expect(findHelpLink().text()).toBe('Learn more.');
      expect(findHelpLink().attributes('href')).toBe(
        helpPagePath('user/analytics/analytics_dashboards'),
      );
    });

    it('does not render any feature or custom dashboards', () => {
      expect(findListItems()).toHaveLength(0);
    });

    it('should track the dashboard list has been viewed', () => {
      expect(trackingSpy).toHaveBeenCalledWith(
        expect.any(String),
        'user_viewed_dashboard_list',
        expect.any(Object),
      );
    });
  });

  describe('for projects', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should render the page description', () => {
      expect(findPageDescription().text()).toContain(
        'Dashboards are created by editing the projects dashboard files.',
      );
    });
  });

  describe('for groups', () => {
    describe('when `groupAnalyticsDashboards` FF is disabled', () => {
      beforeEach(() => {
        createWrapper({ isProject: false });
      });

      it('should render the page description', () => {
        expect(findPageDescription().text()).toContain(
          'Dashboards are created by editing the groups dashboard files.',
        );
      });

      it('should not render the Value streams dashboards link', () => {
        expect(findListItems()).toHaveLength(0);
      });
    });

    describe('when `groupAnalyticsDashboards` FF is enabled', () => {
      beforeEach(() => {
        createWrapper({
          isProject: false,
          glFeatures: { groupAnalyticsDashboards: true },
        });
      });

      it('should render the Value streams dashboards link', () => {
        expect(findListItems()).toHaveLength(1);
        expect(findListItems().at(0).props('dashboard')).toMatchObject(
          VALUE_STREAMS_DASHBOARD_CONFIG,
        );
      });
    });
  });

  describe('configure custom dashboards project', () => {
    describe('when user has permission', () => {
      it('shows the custom dashboard setup alert', () => {
        createWrapper({ customDashboardsProject: null, canConfigureDashboardsProject: true });

        expect(findConfigureAlert().exists()).toBe(true);
      });
    });

    describe('when user does not have permission', () => {
      beforeEach(() => {
        createWrapper({ customDashboardsProject: null, canConfigureDashboardsProject: false });
      });

      it('does not show the custom dashboard setup alert', () => {
        expect(findConfigureAlert().exists()).toBe(false);
      });
    });
  });

  describe('when the product analytics feature is enabled', () => {
    const FEATURE = 'productAnalytics';

    beforeEach(() => {
      mockAnalyticsDashboardsHandler = jest
        .fn()
        .mockResolvedValue(TEST_ALL_DASHBOARDS_GRAPHQL_SUCCESS_RESPONSE);

      createWrapper({
        features: [FEATURE],
      });
    });

    describe('and the feature has not been set up', () => {
      it('renders the feature component', () => {
        expect(findProductAnalyticsOnboarding().exists()).toBe(true);
      });

      // TODO: Update when backend returns dashboards only for onboarded features
      // https://gitlab.com/gitlab-org/gitlab/-/issues/411608
      it('does not render any dashboards', () => {
        expect(findListItems()).toHaveLength(0);
      });

      it('does not render a loading state', async () => {
        await waitForPromises();

        expect(findListLoadingSkeletons()).toHaveLength(0);
      });
    });

    describe('and the feature has been set up', () => {
      beforeEach(() => {
        findProductAnalyticsOnboarding().vm.$emit('complete');
      });

      it('does not render the feature component', () => {
        expect(findProductAnalyticsOnboarding().exists()).toBe(false);
      });

      it('renders a loading state', () => {
        expect(findListLoadingSkeletons()).toHaveLength(2);
      });

      describe('once loaded', () => {
        beforeEach(() => {
          return waitForPromises();
        });

        it('does not render a loading state', () => {
          expect(findListLoadingSkeletons()).toHaveLength(0);
        });

        it('renders a list item for each custom and feature dashboard', () => {
          const expectedDashboards =
            TEST_ALL_DASHBOARDS_GRAPHQL_SUCCESS_RESPONSE.data?.project?.customizableDashboards
              ?.nodes;

          expect(findListItems()).toHaveLength(expectedDashboards.length);

          expectedDashboards.forEach(async (dashboard, idx) => {
            const dashboardItem = findListItems().at(idx);
            expect(dashboardItem.props('dashboard')).toEqual(dashboard);
            expect(dashboardItem.attributes()['data-event-tracking']).toBe(
              'user_visited_dashboard',
            );

            InternalEvents.bindInternalEventDocument(dashboardItem.element);
            await dashboardItem.trigger('click');
            await nextTick();

            expect(trackingSpy).toHaveBeenCalledWith(
              expect.any(String),
              'user_visited_dashboard',
              expect.any(Object),
            );
          });
        });
      });
    });

    describe('and the feature component throws an error', () => {
      const message = 'some error';
      const error = new Error(message);

      beforeEach(() => {
        return findProductAnalyticsOnboarding().vm.$emit('error', error, true, message);
      });

      it('creates an alert for the error', () => {
        expect(createAlert).toHaveBeenCalledWith({
          captureError: true,
          message,
          error,
        });
      });

      it('dimisses the alert when the component is destroyed', async () => {
        wrapper.destroy();

        await nextTick();

        expect(mockAlertDismiss).toHaveBeenCalled();
      });
    });
  });

  describe('when the combinedAnalyticsDashboardsEditor feature flag is enabled', () => {
    beforeEach(() => {
      createWrapper({ glFeatures: { combinedAnalyticsDashboardsEditor: true } });
    });

    it('renders the create new dashboard button', () => {
      expect(findNewDashboardButton().exists()).toBe(true);
    });

    it('does not render the visualization designer button', () => {
      expect(findVisualizationDesignerButton().exists()).toBe(false);
    });
  });

  describe('when the combinedAnalyticsVisualizationEditor feature flag is enabled', () => {
    beforeEach(() => {
      createWrapper({ glFeatures: { combinedAnalyticsVisualizationEditor: true } });
    });

    it('renders the visualization designer button', () => {
      expect(findVisualizationDesignerButton().exists()).toBe(true);
    });

    it('does not render the create new dashboard button', () => {
      expect(findNewDashboardButton().exists()).toBe(false);
    });
  });
});
