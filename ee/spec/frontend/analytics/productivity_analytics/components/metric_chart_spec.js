import { GlLoadingIcon, GlDropdown, GlDropdownItem, GlAlert, GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import MetricChart from 'ee/analytics/productivity_analytics/components/metric_chart.vue';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR } from '~/lib/utils/http_status';

describe('MetricChart component', () => {
  let wrapper;

  const defaultProps = {
    title: 'My Chart',
  };

  const mockChart = 'mockChart';

  const metricTypes = [
    {
      key: 'time_to_merge',
      label: 'Time from last commit to merge',
    },
    {
      key: 'time_to_last_commit',
      label: 'Time from first comment to last commit',
    },
  ];

  const factory = (props = defaultProps) => {
    wrapper = shallowMount(MetricChart, {
      propsData: { ...props },
      slots: {
        default: mockChart,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findLoadingIndicator = () => wrapper.findComponent(GlLoadingIcon);
  const findInfoMessage = () => wrapper.findComponent(GlAlert);
  const findMetricDropdown = () => wrapper.findComponent(GlDropdown);
  const findMetricDropdownItems = () => findMetricDropdown().findAllComponents(GlDropdownItem);
  const findChartSlot = () => wrapper.findComponent({ ref: 'chart' });

  describe('template', () => {
    describe('when title exists', () => {
      beforeEach(() => {
        factory();
      });

      it('renders a title', () => {
        expect(wrapper.text()).toContain('My Chart');
      });
    });

    describe("when title doesn't exist", () => {
      beforeEach(() => {
        factory({ title: null, description: null });
      });

      it("doesn't render a title", () => {
        expect(wrapper.text()).not.toContain('My Chart');
      });
    });

    describe('when isLoading is true', () => {
      beforeEach(() => {
        factory({ isLoading: true });
      });

      it('matches the snapshot', () => {
        expect(wrapper.element).toMatchSnapshot();
      });

      it('renders a loading indicator', () => {
        expect(findLoadingIndicator().exists()).toBe(true);
      });
    });

    describe('when isLoading is false', () => {
      const isLoading = false;

      it('does not render a loading indicator', () => {
        factory({ isLoading });
        expect(findLoadingIndicator().exists()).toBe(false);
      });

      describe('and chart data is empty', () => {
        beforeEach(() => {
          factory({ isLoading, chartData: [] });
        });

        it('matches the snapshot', () => {
          expect(wrapper.element).toMatchSnapshot();
        });

        it('does not show the slot for the chart', () => {
          expect(findChartSlot().exists()).toBe(false);
        });

        describe('and there is no error', () => {
          it('shows a "no data" info text', () => {
            expect(findInfoMessage().text()).toBe(
              'There is no data available. Please change your selection.',
            );
          });
        });

        describe('and there is a 500 error', () => {
          it('shows a "too much data" info text', () => {
            factory({ isLoading, chartData: [], errorCode: HTTP_STATUS_INTERNAL_SERVER_ERROR });

            expect(findInfoMessage().text()).toBe(
              'There is too much data to calculate. Please change your selection.',
            );
          });
        });
      });

      describe('and chartData is not empty', () => {
        const chartData = [[0, 1]];

        describe('and metricTypes exist', () => {
          beforeEach(() => {
            factory({ isLoading, metricTypes, chartData });
          });

          it('matches the snapshot', () => {
            expect(wrapper.element).toMatchSnapshot();
          });

          it('renders a metric dropdown', () => {
            expect(findMetricDropdown().exists()).toBe(true);
          });

          it('renders a dropdown item for each item in metricTypes', () => {
            expect(findMetricDropdownItems()).toHaveLength(2);
          });

          it('should emit `metricTypeChange` event when dropdown item gets clicked', () => {
            jest.spyOn(wrapper.vm, '$emit');

            findMetricDropdownItems().at(0).vm.$emit('click');

            expect(wrapper.vm.$emit).toHaveBeenCalledWith('metricTypeChange', 'time_to_merge');
          });

          it('should set the `invisible` class on the icon of the first dropdown item', async () => {
            wrapper.setProps({ selectedMetric: 'time_to_last_commit' });

            await nextTick();
            expect(findMetricDropdownItems().at(0).findComponent(GlIcon).classes()).toContain(
              'invisible',
            );
          });
        });

        describe('and a description exists', () => {
          it('renders a description', () => {
            factory({ isLoading, chartData, description: 'Test description' });
            expect(wrapper.text()).toContain('Test description');
          });
        });

        it('contains chart from slot', () => {
          factory({ isLoading, chartData });
          expect(findChartSlot().text()).toBe(mockChart);
        });
      });
    });
  });

  describe('computed', () => {
    describe('hasMetricTypes', () => {
      it('returns true if metricTypes exist', () => {
        factory({ metricTypes });
        expect(wrapper.vm.hasMetricTypes).toBe(2);
      });

      it('returns true if no metricTypes exist', () => {
        factory();
        expect(wrapper.vm.hasMetricTypes).toBe(0);
      });
    });

    describe('metricDropdownLabel', () => {
      describe('when a metric is selected', () => {
        it('returns the label of the currently selected metric', () => {
          factory({ metricTypes, selectedMetric: 'time_to_merge' });
          expect(wrapper.vm.metricDropdownLabel).toBe('Time from last commit to merge');
        });
      });

      describe('when no metric is selected', () => {
        it('returns the default dropdown label', () => {
          factory({ metricTypes });
          expect(wrapper.vm.metricDropdownLabel).toBe('Please select a metric');
        });
      });
    });

    describe('hasChartData', () => {
      describe('when chartData is an object', () => {
        it('returns true if chartData is not empty', () => {
          factory({ chartData: { 1: 0 } });
          expect(wrapper.vm.hasChartData).toBe(true);
        });

        it('returns false if chartData is empty', () => {
          factory({ chartData: {} });
          expect(wrapper.vm.hasChartData).toBe(false);
        });
      });

      describe('when chartData is an array', () => {
        it('returns true if chartData is not empty', () => {
          factory({ chartData: [[1, 0]] });
          expect(wrapper.vm.hasChartData).toBe(true);
        });

        it('returns false if chartData is empty', () => {
          factory({ chartData: [] });
          expect(wrapper.vm.hasChartData).toBe(false);
        });
      });
    });
  });

  describe('methods', () => {
    describe('isSelectedMetric', () => {
      it('returns true if the given key matches the selectedMetric prop', () => {
        factory({ selectedMetric: 'time_to_merge' });
        expect(wrapper.vm.isSelectedMetric('time_to_merge')).toBe(true);
      });
    });
  });
});
