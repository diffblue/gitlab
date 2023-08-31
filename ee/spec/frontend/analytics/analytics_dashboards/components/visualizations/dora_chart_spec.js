import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DoraChart from 'ee/analytics/analytics_dashboards/components/visualizations/dora_chart.vue';
import ComparisonChart from 'ee/analytics/dashboards/components/comparison_chart.vue';

describe('LineChart Visualization', () => {
  let wrapper;

  const namespace = {
    title: 'Awesome Co. project',
    requestPath: 'some/fake/path',
    isProject: true,
  };

  const excludeMetrics = ['metric_one', 'metric_two'];
  const filterLabels = ['label_a'];

  const defaultData = {
    namespace,
    excludeMetrics,
    filterLabels,
  };

  const findChart = () => wrapper.findComponent(ComparisonChart);

  const createWrapper = (props = {}) => {
    wrapper = shallowMountExtended(DoraChart, {
      propsData: {
        data: defaultData,
        options: {},
        ...props,
      },
    });
  };

  describe('when mounted', () => {
    it('renders the comparison chart component', () => {
      createWrapper();

      expect(findChart().props()).toMatchObject({
        excludeMetrics,
        filterLabels,
        isProject: true,
        requestPath: 'some/fake/path',
      });
    });
  });
});
