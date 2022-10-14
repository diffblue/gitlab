import { mountExtended } from 'helpers/vue_test_utils_helper';
import AnalyticsDashboard from 'ee/product_analytics/dashboards/components/analytics_dashboard.vue';

describe('ee/product_analytics/dashboards/components/analytics_dashboard.vue', () => {
  let wrapper;

  afterEach(() => {
    wrapper.destroy();
  });

  const createWrapper = (data = {}) => {
    wrapper = mountExtended(AnalyticsDashboard, {
      data() {
        return {
          dashboard: {},
          ...data,
        };
      },
    });
  };

  describe('when mounted', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should render', () => {
      expect(wrapper.exists()).toBe(true);
    });
  });
});
