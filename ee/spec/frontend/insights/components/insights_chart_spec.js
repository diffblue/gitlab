import { GlColumnChart, GlLineChart, GlStackedColumnChart } from '@gitlab/ui/dist/charts';
import { shallowMount } from '@vue/test-utils';

import InsightsChart from 'ee/insights/components/insights_chart.vue';
import InsightsChartError from 'ee/insights/components/insights_chart_error.vue';
import { CHART_TYPES } from 'ee/insights/constants';
import {
  chartInfo,
  barChartData,
  lineChartData,
  stackedBarChartData,
} from 'ee_jest/insights/mock_data';
import ChartSkeletonLoader from '~/vue_shared/components/resizable_chart/skeleton_loader.vue';

const DEFAULT_PROPS = {
  loaded: false,
  type: chartInfo.type,
  title: chartInfo.title,
  data: null,
  error: '',
};

describe('Insights chart component', () => {
  let wrapper;

  const factory = (propsData) =>
    shallowMount(InsightsChart, {
      propsData,
      stubs: { 'gl-column-chart': true, 'insights-chart-error': true },
    });

  describe('when chart is loading', () => {
    it('displays the chart loader in the container', () => {
      wrapper = factory(DEFAULT_PROPS);

      expect(wrapper.findComponent(ChartSkeletonLoader).exists()).toBe(true);
    });
  });

  describe.each`
    type                       | component               | name                      | data
    ${CHART_TYPES.BAR}         | ${GlColumnChart}        | ${'GlColumnChart'}        | ${barChartData}
    ${CHART_TYPES.LINE}        | ${GlLineChart}          | ${'GlLineChart'}          | ${lineChartData}
    ${CHART_TYPES.STACKED_BAR} | ${GlStackedColumnChart} | ${'GlStackedColumnChart'} | ${stackedBarChartData}
    ${CHART_TYPES.PIE}         | ${GlColumnChart}        | ${'GlColumnChart'}        | ${barChartData}
  `('when chart is loaded', ({ type, component, name, data }) => {
    it(`when ${type} is passed: displays the a ${name}-chart in container and not the loader`, () => {
      wrapper = factory({
        ...DEFAULT_PROPS,
        loaded: true,
        type,
        data,
      });

      expect(wrapper.findComponent(ChartSkeletonLoader).exists()).toBe(false);
      expect(wrapper.findComponent(component).exists()).toBe(true);
    });
  });

  describe('when chart receives an error', () => {
    const error = 'my error';

    beforeEach(() => {
      wrapper = factory({
        ...DEFAULT_PROPS,
        data: {},
        error,
      });
    });

    it('displays info about the error', () => {
      expect(wrapper.findComponent(ChartSkeletonLoader).exists()).toBe(false);
      expect(wrapper.findComponent(InsightsChartError).exists()).toBe(true);
    });
  });
});
