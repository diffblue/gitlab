import CubeLineChart from 'ee/product_analytics/dashboards/components/widgets/cube_line_chart.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WidgetsBase from 'ee/vue_shared/components/customizable_dashboard/widgets_base.vue';
import { dashboard } from './mock_data';

describe('WidgetsBase', () => {
  const widgetConfig = dashboard.widgets[0];

  let wrapper;

  const createWrapper = (props = {}) => {
    wrapper = shallowMountExtended(WidgetsBase, {
      propsData: {
        ...props,
      },
    });
  };

  const findWidget = () => wrapper.findComponent(CubeLineChart);
  const findWidgetTitle = () => wrapper.findByTestId('widget-title');

  describe('when mounted', () => {
    beforeEach(() => {
      createWrapper({
        component: widgetConfig.component,
        title: widgetConfig.title,
        data: widgetConfig.data,
        chartOptions: widgetConfig.chartOptions,
        customizations: widgetConfig.customizations,
      });
    });

    it('should render', () => {
      expect(findWidgetTitle().text()).toBe(widgetConfig.title);
      expect(findWidget().props()).toStrictEqual({
        data: widgetConfig.data,
        chartOptions: widgetConfig.chartOptions,
        customizations: widgetConfig.customizations,
      });
    });
  });
});
