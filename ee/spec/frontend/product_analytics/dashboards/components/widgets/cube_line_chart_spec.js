import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CubeLineChart from 'ee/product_analytics/dashboards/components/widgets/cube_line_chart.vue';

describe('CubeLineChart', () => {
  let wrapper;

  const createWrapper = (props = {}) => {
    wrapper = shallowMountExtended(CubeLineChart, {
      propsData: {
        data: {},
        chartOptions: {},
        customizations: {},
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
