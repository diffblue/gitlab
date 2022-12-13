import {
  percentChange,
  extractDoraMetrics,
  hasDoraMetricValues,
  generateDoraTimePeriodComparisonTable,
  generateSparklineCharts,
  mergeSparklineCharts,
} from 'ee/analytics/dashboards/utils';
import {
  DEPLOYMENT_FREQUENCY_METRIC_TYPE,
  CHANGE_FAILURE_RATE,
  LEAD_TIME_FOR_CHANGES,
  TIME_TO_RESTORE_SERVICE,
} from 'ee/api/dora_api';
import {
  LEAD_TIME_METRIC_TYPE,
  CYCLE_TIME_METRIC_TYPE,
  ISSUES_METRIC_TYPE,
  DEPLOYS_METRIC_TYPE,
} from '~/api/analytics_api';
import {
  mockMonthToDate,
  mockMonthToDateTimePeriod,
  mockPreviousMonthTimePeriod,
  mockTwoMonthsAgoTimePeriod,
  mockThreeMonthsAgoTimePeriod,
  mockComparativeTableData,
  mockMonthToDateApiResponse,
  mockChartsTimePeriods,
  mockChartData,
} from './mock_data';

describe('Analytics Dashboards utils', () => {
  describe('percentChange', () => {
    it.each`
      current | previous | result
      ${10}   | ${20}    | ${-0.5}
      ${5}    | ${2}     | ${1.5}
      ${5}    | ${0}     | ${0}
      ${0}    | ${5}     | ${0}
    `('calculates the percentage change given 2 numbers', ({ current, previous, result }) => {
      expect(percentChange({ current, previous })).toBe(result);
    });
  });

  describe('generateDoraTimePeriodComparisonTable', () => {
    let res = {};

    beforeEach(() => {
      res = generateDoraTimePeriodComparisonTable([
        mockMonthToDateTimePeriod,
        mockPreviousMonthTimePeriod,
        mockTwoMonthsAgoTimePeriod,
        mockThreeMonthsAgoTimePeriod,
      ]);
    });

    it('returns the comparison table fields for each row', () => {
      res.forEach((row) => {
        expect(Object.keys(row)).toEqual(['metric', 'thisMonth', 'lastMonth', 'twoMonthsAgo']);
      });
    });

    it('calculates the changes between the 2 time periods', () => {
      expect(res).toEqual(mockComparativeTableData);
    });
  });

  describe('generateSparklineCharts', () => {
    let res = {};

    beforeEach(() => {
      res = generateSparklineCharts(mockChartsTimePeriods);
    });

    it('returns the chart data for each metric', () => {
      expect(res).toEqual(mockChartData);
    });
  });

  describe('mergeSparklineCharts', () => {
    it('returns the table data with the additive chart data', () => {
      const chart = { data: [1, 2, 3] };
      const rowNoChart = { metric: { identifier: 'noChart' } };
      const rowWithChart = { metric: { identifier: 'withChart' } };

      expect(mergeSparklineCharts([rowNoChart, rowWithChart], { withChart: chart })).toEqual([
        rowNoChart,
        { ...rowWithChart, chart },
      ]);
    });
  });

  describe('extractDoraMetrics', () => {
    let res = {};
    beforeEach(() => {
      res = extractDoraMetrics(mockMonthToDateApiResponse);
    });

    it('returns an object with all of the DORA and cycle metrics', () => {
      expect(Object.keys(res)).toEqual([
        LEAD_TIME_FOR_CHANGES,
        TIME_TO_RESTORE_SERVICE,
        CHANGE_FAILURE_RATE,
        DEPLOYMENT_FREQUENCY_METRIC_TYPE,
        LEAD_TIME_METRIC_TYPE,
        CYCLE_TIME_METRIC_TYPE,
        ISSUES_METRIC_TYPE,
        DEPLOYS_METRIC_TYPE,
      ]);
    });

    it('returns the data for each DORA metric', () => {
      expect(res).toEqual(mockMonthToDate);
      expect(extractDoraMetrics([])).toEqual({});
    });
  });

  describe('hasDoraMetricValues', () => {
    it('returns false if only non-DORA metrics contain a value > 0', () => {
      const timePeriods = [{ nonDoraMetric: { value: 100 } }];
      expect(hasDoraMetricValues(timePeriods)).toBe(false);
    });

    it('returns false if all DORA metrics contain a non-numerical value', () => {
      const timePeriods = [{ [LEAD_TIME_FOR_CHANGES]: { value: 'YEET' } }];
      expect(hasDoraMetricValues(timePeriods)).toBe(false);
    });

    it('returns false if all DORA metrics contain a value == 0', () => {
      const timePeriods = [{ [LEAD_TIME_FOR_CHANGES]: { value: 0 } }];
      expect(hasDoraMetricValues(timePeriods)).toBe(false);
    });

    it('returns true if any DORA metrics contain a value > 0', () => {
      const timePeriods = [
        {
          [LEAD_TIME_FOR_CHANGES]: { value: 0 },
          [CHANGE_FAILURE_RATE]: { value: 100 },
        },
      ];
      expect(hasDoraMetricValues(timePeriods)).toBe(true);
    });
  });
});
