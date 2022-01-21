import { GlAreaChart } from '@gitlab/ui/dist/charts';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import { TOTAL_REQUESTS, ANOMALOUS_REQUESTS } from 'ee/threat_monitoring/components/constants';
import StatisticsHistory from 'ee/threat_monitoring/components/statistics_history.vue';
import { mockNominalHistory, mockAnomalousHistory } from '../mocks/mock_data';

let resizeCallback = null;
const MockResizeObserverDirective = {
  bind(el, { value }) {
    resizeCallback = value;
  },

  simulateResize() {
    // Let tests fail if callback throws or isn't callable
    resizeCallback();
  },

  unbind() {
    resizeCallback = null;
  },
};

Vue.directive('gl-resize-observer-directive', MockResizeObserverDirective);

describe('StatisticsHistory component', () => {
  let wrapper;

  const factory = ({ options } = {}) => {
    wrapper = shallowMount(StatisticsHistory, {
      propsData: {
        data: {
          anomalous: { title: 'Anomoulous', values: mockAnomalousHistory },
          nominal: { title: 'Total', values: mockNominalHistory },
          from: 'foo',
          to: 'bar',
        },
        yLegend: 'Requests',
      },
      ...options,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findChart = () => wrapper.find(GlAreaChart);

  describe('the data passed to the chart', () => {
    beforeEach(() => {
      factory();
    });

    it('is structured correctly', () => {
      expect(findChart().props('data')).toMatchObject([
        { data: mockAnomalousHistory },
        { data: mockNominalHistory },
      ]);
    });
  });

  describe('the options passed to the chart', () => {
    beforeEach(() => {
      factory();
    });

    it('sets the xAxis range', () => {
      expect(findChart().props('option')).toMatchObject({
        xAxis: {
          min: 'foo',
          max: 'bar',
        },
      });
    });
  });

  describe('given the component needs to resize', () => {
    let mockChartInstance;
    beforeEach(() => {
      factory();

      mockChartInstance = {
        resize: jest.fn(),
      };
    });

    describe('given the chart has not emitted the created event', () => {
      beforeEach(() => {
        MockResizeObserverDirective.simulateResize();
      });

      it('there is no attempt to resize the chart instance', () => {
        expect(mockChartInstance.resize).not.toHaveBeenCalled();
      });
    });

    describe('given the chart has emitted the created event', () => {
      beforeEach(() => {
        findChart().vm.$emit('created', mockChartInstance);
        MockResizeObserverDirective.simulateResize();
      });

      it('the chart instance is resized', () => {
        expect(mockChartInstance.resize).toHaveBeenCalledTimes(1);
      });
    });
  });

  describe('chart tooltip', () => {
    beforeEach(() => {
      const mockParams = {
        seriesData: [
          {
            seriesName: ANOMALOUS_REQUESTS,
            value: mockAnomalousHistory[0],
          },
          {
            seriesName: TOTAL_REQUESTS,
            value: mockNominalHistory[0],
          },
        ],
      };

      factory({
        options: {
          stubs: {
            GlAreaChart: {
              props: ['formatTooltipText'],
              mounted() {
                this.formatTooltipText(mockParams);
              },
              template: `
                <div>
                  <slot name="tooltip-title"></slot>
                  <slot name="tooltip-content"></slot>
                </div>`,
            },
          },
        },
      });

      return wrapper.vm.$nextTick();
    });

    it('renders the title and series data correctly', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });
});
