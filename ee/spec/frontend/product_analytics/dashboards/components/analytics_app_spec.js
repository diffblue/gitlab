import { shallowMount } from '@vue/test-utils';
import AnalyticsApp from 'ee/product_analytics/dashboards/components/analytics_app.vue';

describe('AnalyticsApp', () => {
  let wrapper;

  const findRouterView = () => wrapper.findComponent({ ref: 'router-view' });

  const createWrapper = () => {
    wrapper = shallowMount(AnalyticsApp, {
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
