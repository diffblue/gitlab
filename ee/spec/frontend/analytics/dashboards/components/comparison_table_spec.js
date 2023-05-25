import { mountExtended } from 'helpers/vue_test_utils_helper';
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

  const createWrapper = (props = {}) => {
    wrapper = mountExtended(ComparisonTable, {
      propsData: {
        tableData: mockComparativeTableData,
        requestPath: 'groups/test',
        isProject: false,
        now,
        ...props,
      },
    });
  };

  const findMetricTableCell = (identifier) => wrapper.findByTestId(`${identifier}_metric_cell`);
  const findChart = () => wrapper.findByTestId('metric_chart');
  const findChartSkeleton = () => wrapper.findByTestId('metric_chart_skeleton');

  it.each(Object.keys(TABLE_METRICS))('renders table cell for %s metric', (identifier) => {
    createWrapper();
    expect(findMetricTableCell(identifier).exists()).toBe(true);
    expect(findMetricTableCell(identifier).props('identifier')).toBe(identifier);
  });

  describe('sparkline chart', () => {
    const mockMetric = { identifier: 'lead_time', value: 'Lead Time' };

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
