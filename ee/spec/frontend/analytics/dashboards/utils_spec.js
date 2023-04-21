import { UNITS } from 'ee/analytics/dashboards/constants';
import {
  percentChange,
  formatMetric,
  extractDoraMetrics,
  hasDoraMetricValues,
  generateDoraTimePeriodComparisonTable,
  generateSparklineCharts,
  mergeSparklineCharts,
  hasTrailingDecimalZero,
  generateDateRanges,
  generateChartTimePeriods,
  generateDashboardTableFields,
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
  mockSubsetChartsTimePeriods,
  mockSubsetChartData,
  MOCK_TABLE_TIME_PERIODS,
  MOCK_CHART_TIME_PERIODS,
  MOCK_DASHBOARD_TABLE_FIELDS,
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

  describe.each([
    { units: UNITS.PER_DAY, suffix: '/d' },
    { units: UNITS.DAYS, suffix: ' d' },
    { units: UNITS.PERCENT, suffix: '%' },
  ])('formatMetric(*, $units)', ({ units, suffix }) => {
    it.each`
      value      | result
      ${0}       | ${'0.0'}
      ${10}      | ${'10.0'}
      ${-10}     | ${'-10.0'}
      ${1}       | ${'1.0'}
      ${-1}      | ${'-1.0'}
      ${0.1}     | ${'0.1'}
      ${-0.99}   | ${'-0.99'}
      ${0.099}   | ${'0.099'}
      ${-0.01}   | ${'-0.01'}
      ${0.0099}  | ${'0.0099'}
      ${-0.0001} | ${'-0.0001'}
    `('returns $result for a metric with the value $value', ({ value, result }) => {
      expect(formatMetric(value, units)).toBe(`${result}${suffix}`);
    });
  });

  describe('hasTrailingDecimalZero', () => {
    it.each`
      value         | result
      ${'-10.0/d'}  | ${false}
      ${'0.099/d'}  | ${false}
      ${'0.0099%'}  | ${false}
      ${'0.10%'}    | ${true}
      ${'-0.010 d'} | ${true}
    `('returns $result for value $value', ({ value, result }) => {
      expect(hasTrailingDecimalZero(value)).toBe(result);
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

    it('returns the comparison table fields + metadata for each row', () => {
      res.forEach((row) => {
        expect(Object.keys(row)).toEqual([
          'invertTrendColor',
          'metric',
          'thisMonth',
          'lastMonth',
          'twoMonthsAgo',
        ]);
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

    describe('with metrics keys', () => {
      beforeEach(() => {
        res = generateSparklineCharts(mockSubsetChartsTimePeriods);
      });

      it('returns 0 for each missing metric', () => {
        expect(res).toEqual(mockSubsetChartData);
      });
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

  describe('generateDateRanges', () => {
    it('return correct value', () => {
      const now = MOCK_TABLE_TIME_PERIODS[0].end;
      expect(generateDateRanges(now)).toEqual(MOCK_TABLE_TIME_PERIODS);
    });

    it('return incorrect value', () => {
      const now = MOCK_TABLE_TIME_PERIODS[2].start;
      expect(generateDateRanges(now)).not.toEqual(MOCK_TABLE_TIME_PERIODS);
    });
  });

  describe('generateChartTimePeriods', () => {
    it('return correct value', () => {
      const now = MOCK_TABLE_TIME_PERIODS[0].end;
      expect(generateChartTimePeriods(now)).toEqual(MOCK_CHART_TIME_PERIODS);
    });

    it('return incorrect value', () => {
      const now = MOCK_TABLE_TIME_PERIODS[2].start;
      expect(generateChartTimePeriods(now)).not.toEqual(MOCK_CHART_TIME_PERIODS);
    });
  });

  describe('generateDashboardTableFields', () => {
    it('return correct value', () => {
      const now = MOCK_TABLE_TIME_PERIODS[0].end;
      expect(generateDashboardTableFields(now)).toEqual(MOCK_DASHBOARD_TABLE_FIELDS);
    });

    it('return incorrect value', () => {
      const now = MOCK_TABLE_TIME_PERIODS[2].start;
      expect(generateDashboardTableFields(now)).not.toEqual(MOCK_DASHBOARD_TABLE_FIELDS);
    });
  });
});
