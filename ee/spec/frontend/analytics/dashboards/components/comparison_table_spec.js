import { mountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import {
  TABLE_METRICS,
  CHART_GRADIENT,
  CHART_GRADIENT_INVERTED,
} from 'ee/analytics/dashboards/constants';
import ComparisonTable from 'ee/analytics/dashboards/components/comparison_table.vue';
import { mockComparativeTableData } from '../mock_data';

describe('Comparison table', () => {
  let wrapper;

  const now = new Date();
  const mockMetric = { identifier: 'lead_time', value: 'Lead Time' };

  const createWrapper = (props = {}) => {
    wrapper = mountExtended(ComparisonTable, {
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      propsData: {
        tableData: mockComparativeTableData,
        requestPath: 'groups/test',
        isProject: false,
        now,
        ...props,
      },
    });
  };

  const findMetricTableCell = (identifier) => wrapper.findByTestId(`${identifier}-metric-cell`);
  const findMetricComparisonSkeletons = () => wrapper.findAllByTestId('metric-comparison-skeleton');
  const findChart = () => wrapper.findByTestId('metric-chart');
  const findChartSkeleton = () => wrapper.findByTestId('metric-chart-skeleton');
  const findTrendIndicator = () => wrapper.findByTestId('metric-trend-indicator');
  const findValueLimitInfoIcon = () => wrapper.findByTestId('metric-max-value-info-icon');

  it.each(Object.keys(TABLE_METRICS))('renders table cell for %s metric', (identifier) => {
    createWrapper();
    expect(findMetricTableCell(identifier).exists()).toBe(true);
    expect(findMetricTableCell(identifier).props('identifier')).toBe(identifier);
  });

  it('shows loading skeletons for each metric comparison cell', () => {
    createWrapper({ tableData: [{ metric: mockMetric }] });
    expect(findMetricComparisonSkeletons().length).toBe(3);
  });

  describe('date range table cell', () => {
    const valueLimit = {
      max: 10001,
      mask: '10000+',
      description: 'The maximum value has been exceeded',
    };

    const mockTimePeriods = [
      {
        change: 0.25,
        value: valueLimit.mask,
        valueLimitMessage: valueLimit.description,
      },
      {
        change: 0.6,
        value: 8000,
      },
      {
        change: 0,
        value: 6000,
      },
    ];

    describe('When value has exceeded maximum value', () => {
      const [timePeriodWithMaximum] = mockTimePeriods;

      beforeEach(() => {
        createWrapper({
          tableData: [
            {
              metric: mockMetric,
              thisMonth: timePeriodWithMaximum,
              valueLimit,
            },
          ],
        });
      });

      it('displays correct value', () => {
        const { value } = timePeriodWithMaximum;

        expect(wrapper.findByText(value).exists()).toBe(true);
      });

      it(`should render value limit info icon with tooltip`, () => {
        const tooltip = getBinding(findValueLimitInfoIcon().element, 'gl-tooltip');

        expect(findValueLimitInfoIcon().exists()).toBe(true);
        expect(tooltip).toBeDefined();
        expect(findValueLimitInfoIcon().attributes('title')).toBe(
          timePeriodWithMaximum.valueLimitMessage,
        );
      });

      it('should not render trend indicator', () => {
        expect(findTrendIndicator().exists()).toBe(false);
      });
    });

    describe.each`
      description                                               | timePeriod            | shouldRenderTrendIndicator
      ${'When value has changed from previous month'}           | ${mockTimePeriods[1]} | ${true}
      ${'When value has not changed or exceeded maximum value'} | ${mockTimePeriods[2]} | ${false}
    `('$description', ({ timePeriod, shouldRenderTrendIndicator }) => {
      beforeEach(() => {
        createWrapper({
          tableData: [
            {
              metric: mockMetric,
              thisMonth: timePeriod,
              valueLimit,
            },
          ],
        });
      });

      it('displays correct value', () => {
        const { value } = timePeriod;

        expect(wrapper.findByText(`${value}`).exists()).toBe(true);
      });

      it(`${
        shouldRenderTrendIndicator ? 'should render' : 'should not render'
      } trend indicator`, () => {
        expect(findTrendIndicator().exists()).toBe(shouldRenderTrendIndicator);
      });

      it(`should not render value limit info icon`, () => {
        expect(findValueLimitInfoIcon().exists()).toBe(false);
      });
    });
  });

  describe('sparkline chart', () => {
    beforeEach(() => {
      // Needed due to a deprecation in the GlSparkline API:
      // https://gitlab.com/gitlab-org/gitlab-ui/-/issues/2119
      // eslint-disable-next-line no-console
      console.warn = jest.fn();
    });

    it('renders the skeleton when there is no data', () => {
      createWrapper({ tableData: [{ metric: mockMetric }] });
      expect(findChart().exists()).toBe(false);
      expect(findChartSkeleton().exists()).toBe(true);
    });

    it('renders the line when there is data', () => {
      createWrapper({
        tableData: [
          {
            metric: mockMetric,
            chart: {
              data: [['', 1]],
            },
          },
        ],
      });
      expect(findChartSkeleton().exists()).toBe(false);
      expect(findChart().exists()).toBe(true);
    });

    it('applies the default gradient', () => {
      createWrapper({
        tableData: [
          {
            metric: mockMetric,
            chart: {
              data: [['', 1]],
            },
          },
        ],
      });
      expect(findChart().props('gradient')).toEqual(CHART_GRADIENT);
    });

    it('applies the inverted gradient when `invertTrendColor == true`', () => {
      createWrapper({
        tableData: [
          {
            metric: mockMetric,
            invertTrendColor: true,
            chart: {
              data: [['', 1]],
            },
          },
        ],
      });
      expect(findChart().props('gradient')).toEqual(CHART_GRADIENT_INVERTED);
    });
  });
});
