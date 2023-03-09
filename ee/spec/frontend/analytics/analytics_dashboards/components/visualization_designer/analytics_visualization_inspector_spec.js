import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import AnalyticsVisualizationInspector from 'ee/analytics/analytics_dashboards/components/visualization_designer/analytics_visualization_inspector.vue';

describe('AnalyticsVisualizationInspector', () => {
  let wrapper;

  const createWrapper = (selectedVisualizationType = '') => {
    wrapper = shallowMountExtended(AnalyticsVisualizationInspector, {
      propsData: {
        selectedVisualizationType,
      },
    });
  };

  it.each`
    visualizationButton    | visualizationType
    ${'linechart-button'}  | ${'LineChart'}
    ${'datatable-button'}  | ${'DataTable'}
    ${'singlestat-button'} | ${'SingleStat'}
  `(
    'calls from overview to select $visualizationType',
    ({ visualizationButton, visualizationType }) => {
      createWrapper();
      const overvViewButton = wrapper.findByTestId(visualizationButton);

      expect(overvViewButton.exists()).toBe(true);
      overvViewButton.vm.$emit('click');

      expect(wrapper.emitted('selectVisualizationType')[0]).toStrictEqual([visualizationType]);
    },
  );

  it.each`
    visualizationItem       | visualizationType | visualizationTypeName
    ${'linechart-dd-item'}  | ${'LineChart'}    | ${'Line Chart'}
    ${'datatable-dd-item'}  | ${'DataTable'}    | ${'Data Table'}
    ${'singlestat-dd-item'} | ${'SingleStat'}   | ${'Single Statistic'}
  `(
    'calls from overview to select $visualizationType',
    ({ visualizationItem, visualizationType, visualizationTypeName }) => {
      createWrapper(visualizationType);
      const chartDDItem = wrapper.findByTestId(visualizationItem);

      const chartDD = wrapper.findByTestId('chart-dd');
      expect(chartDD.exists()).toBe(true);
      expect(wrapper.text()).toContain(visualizationTypeName);

      expect(chartDDItem.exists()).toBe(true);
      chartDDItem.vm.$emit('click');
      expect(wrapper.emitted('selectVisualizationType')[0]).toStrictEqual([visualizationType]);
    },
  );
});
