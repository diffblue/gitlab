import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import AnalyticsDashboard from 'ee/product_analytics/dashboards/components/analytics_dashboard.vue';
import CustomizableDashboard from 'ee/vue_shared/components/customizable_dashboard/customizable_dashboard.vue';
import { widgets } from 'ee_jest/vue_shared/components/customizable_dashboard/mock_data';

describe('AnalyticsDashboard', () => {
  let wrapper;

  const createWrapper = (data = {}) => {
    wrapper = shallowMountExtended(AnalyticsDashboard, {
      data() {
        return {
          widgets: [],
          ...data,
        };
      },
    });
  };

  describe('when mounted', () => {
    beforeEach(() => {
      createWrapper({
        widgets,
      });
    });

    it('should render', () => {
      expect(wrapper.findComponent(CustomizableDashboard).props()).toStrictEqual({
        widgets,
        editable: false,
      });
    });
  });
});
