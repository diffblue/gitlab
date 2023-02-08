import { shallowMount } from '@vue/test-utils';
import VueRouter from 'vue-router';
import Vue, { nextTick } from 'vue';
import ProductAnalyticsDashboardsView from 'ee/product_analytics/dashboards/dashboards_view.vue';
import ProductAnalyticsOnboardingSetup from 'ee/product_analytics/onboarding/onboarding_setup.vue';
import DashboardsList from 'ee/product_analytics/dashboards/components/analytics_dashboard_list.vue';
import AnalyticsDashboard from 'ee/product_analytics/dashboards/components/analytics_dashboard.vue';
import AnalyticsPanelDesigner from 'ee/product_analytics/dashboards/components/analytics_panel_designer.vue';
import createAnalyticsRouter from 'ee/product_analytics/router';

describe('ProductAnalyticsDashboardsView', () => {
  let wrapper;
  let router;

  Vue.use(VueRouter);

  const findRouterView = () => wrapper.findComponent({ ref: 'router-view' });

  const createWrapper = () => {
    router = createAnalyticsRouter();

    wrapper = shallowMount(ProductAnalyticsDashboardsView, {
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
        path                   | component
        ${'/'}                 | ${DashboardsList}
        ${'/panel-designer'}   | ${AnalyticsPanelDesigner}
        ${'/setup'}            | ${ProductAnalyticsOnboardingSetup}
        ${'/test-dashboard-1'} | ${AnalyticsDashboard}
        ${'/test-dashboard-2'} | ${AnalyticsDashboard}
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
