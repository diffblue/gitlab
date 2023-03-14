import { GlLineChart } from '@gitlab/ui/dist/charts';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import LineChart from 'ee/analytics/analytics_dashboards/components/visualizations/line_chart.vue';

describe('LineChart Visualization', () => {
  let wrapper;

  const findLineChart = () => wrapper.findComponent(GlLineChart);

  const createWrapper = (props = {}) => {
    wrapper = shallowMountExtended(LineChart, {
      propsData: {
        data: [],
        options: {},
        ...props,
      },
    });
  };

  describe('when mounted', () => {
    beforeEach(() => {
      createWrapper({
        data: [{ name: 'foo' }],
        options: { yAxis: {}, xAxis: {} },
      });
    });

    it('should render the line chart with the provided data and option', () => {
      expect(findLineChart().props()).toMatchObject({
        data: [{ name: 'foo' }],
        option: { yAxis: {}, xAxis: {} },
        height: 'auto',
      });
      expect(findLineChart().attributes('responsive')).toBe('');
    });
  });
});
