import { GlLoadingIcon, GlCollapsibleListbox, GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
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

  const findLoadingIndicator = () => wrapper.findComponent(GlLoadingIcon);
  const findInfoMessage = () => wrapper.findComponent(GlAlert);
  const findMetricDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
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

      describe('and chartData is empty (object)', () => {
        it('does not show the slot for the chart', () => {
          factory({ isLoading, chartData: {} });
          expect(findChartSlot().exists()).toBe(false);
        });
      });

      describe('and chartData is not empty', () => {
        const chartData = [[0, 1]];

        it('does not render a metric dropdown', () => {
          factory({ isLoading, chartData });

          expect(findMetricDropdown().exists()).toBe(false);
        });

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
            expect(findMetricDropdown().props('items')).toHaveLength(2);
          });

          it('should emit `metricTypeChange` event when dropdown item gets clicked', () => {
            findMetricDropdown().vm.$emit('select', metricTypes[0].key);

            expect(wrapper.emitted('metricTypeChange')).toEqual([['time_to_merge']]);
          });

          it('should render the default dropdown label', () => {
            expect(findMetricDropdown().props('toggleText')).toContain('Please select a metric');
          });

          describe('and a metric is selected', () => {
            beforeEach(() => {
              factory({
                ...defaultProps,
                metricTypes,
                chartData,
                selectedMetric: 'time_to_last_commit',
              });
            });

            it('should only set `invisible` class on the icon of first dropdown item', () => {
              expect(findMetricDropdown().props('selected')).toBe(metricTypes[1].key);
            });

            it('renders the correct text in the dropdown', () => {
              expect(findMetricDropdown().props('toggleText')).toBe(
                'Time from first comment to last commit',
              );
            });

            it('should render correct items', () => {
              expect(findMetricDropdown().props('selected')).toBe(metricTypes[1].key);
              expect(findMetricDropdown().props('items')).toEqual(
                metricTypes.map(({ key, label }) => ({ value: key, text: label })),
              );
            });
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

      describe('and chartData is not empty (object)', () => {
        it('contains chart from slot', () => {
          factory({ isLoading, chartData: { 1: 0 } });
          expect(findChartSlot().text()).toBe(mockChart);
        });
      });
    });
  });
});
