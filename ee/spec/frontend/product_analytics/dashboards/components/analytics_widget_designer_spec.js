import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import AnalyticsWidgetDesigner from 'ee/product_analytics/dashboards/components/analytics_widget_designer.vue';

describe('AnalyticsDashboardList', () => {
  let wrapper;

  const findTitleInput = () => wrapper.findByTestId('widget-title-tba');

  const createWrapper = () => {
    wrapper = shallowMountExtended(AnalyticsWidgetDesigner);
  };

  describe('when mounted', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should render title box', () => {
      expect(findTitleInput().exists()).toBe(true);
    });
  });
});
