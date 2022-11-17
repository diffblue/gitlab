import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import LineChart from 'ee/product_analytics/dashboards/components/visualizations/line_chart.vue';

describe('LineChart Visualization', () => {
  let wrapper;

  const createWrapper = (props = {}) => {
    wrapper = shallowMountExtended(LineChart, {
      propsData: {
        data: {},
        options: {},
        ...props,
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
