import { shallowMount } from '@vue/test-utils';
import VueRouter from 'vue-router';
import Vue, { nextTick } from 'vue';
import DashboardsList from 'ee/analytics/analytics_dashboards/components/dashboards_list.vue';
import AnalyticsDashboardsApp from 'ee/analytics/analytics_dashboards/dashboards_app.vue';
import AnalyticsDashboard from 'ee/analytics/analytics_dashboards/components/analytics_dashboard.vue';
import ProductAnalyticsOnboardingView from 'ee/product_analytics/onboarding/onboarding_view.vue';
import ProductAnalyticsOnboardingSetup from 'ee/product_analytics/onboarding/onboarding_setup.vue';
import AnalyticsVisualizationDesigner from 'ee/analytics/analytics_dashboards/components/analytics_visualization_designer.vue';
import createRouter from 'ee/analytics/analytics_dashboards/router';

describe('AnalyticsDashboardsApp', () => {
  let wrapper;
  let router;

  Vue.use(VueRouter);

  const findRouterView = () => wrapper.findComponent({ ref: 'router-view' });

  const createWrapper = () => {
    router = createRouter();

    wrapper = shallowMount(AnalyticsDashboardsApp, {
      router,
      stubs: {
        RouterView: true,
      },
    });
  };

  describe('when mounted', () => {
    beforeEach(() => {
      createWrapper();
    });

    describe('router', () => {
      it.each`
        path                               | component
        ${'/'}                             | ${DashboardsList}
        ${'/visualization-designer'}       | ${AnalyticsVisualizationDesigner}
        ${'/product-analytics-onboarding'} | ${ProductAnalyticsOnboardingView}
        ${'/product-analytics-setup'}      | ${ProductAnalyticsOnboardingSetup}
        ${'/test-dashboard-1'}             | ${AnalyticsDashboard}
        ${'/test-dashboard-2'}             | ${AnalyticsDashboard}
      `('sets component as $component.name for path "$path"', async ({ path, component }) => {
        if (path !== '/') {
          router.push(path);
        }

        await nextTick();

        const [root] = router.currentRoute.matched;

        expect(root.components.default).toBe(component);
      });
    });

    it('should render', () => {
      expect(findRouterView().exists()).toBe(true);
    });
  });
});
