import { shallowMount } from '@vue/test-utils';
import VueRouter from 'vue-router';
import Vue from 'vue';
import AnalyticsDashboardsApp from 'ee/analytics/analytics_dashboards/dashboards_app.vue';
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

    it('should render', () => {
      expect(findRouterView().exists()).toBe(true);
    });
  });
});
