import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { UNITS, DORA_PERFORMERS_SCORE_CATEGORY_TYPES } from 'ee/analytics/dashboards/constants';
import { useFakeDate } from 'helpers/fake_date';
import {
  percentChange,
  formatMetric,
  generateSkeletonTableData,
  generateMetricComparisons,
  generateSparklineCharts,
  mergeTableData,
  hasTrailingDecimalZero,
  generateDateRanges,
  generateChartTimePeriods,
  generateDashboardTableFields,
  generateValueStreamDashboardStartDate,
  groupDoraPerformanceScoreCountsByCategory,
} from 'ee/analytics/dashboards/utils';
import { LEAD_TIME_METRIC_TYPE, CYCLE_TIME_METRIC_TYPE } from '~/api/analytics_api';
import {
  mockMonthToDateTimePeriod,
  mockPreviousMonthTimePeriod,
  mockTwoMonthsAgoTimePeriod,
  mockThreeMonthsAgoTimePeriod,
  mockGeneratedMetricComparisons,
  mockChartsTimePeriods,
  mockChartData,
  mockSubsetChartsTimePeriods,
  mockSubsetChartData,
  MOCK_TABLE_TIME_PERIODS,
  MOCK_CHART_TIME_PERIODS,
  MOCK_DASHBOARD_TABLE_FIELDS,
  mockDoraPerformersScoreResponseData,
} from './mock_data';

describe('Analytics Dashboards utils', () => {
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

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

  describe('generateSkeletonTableData', () => {
    it('returns blank row data for each metric', () => {
      const tableData = generateSkeletonTableData();
      tableData.forEach((data) =>
        expect(Object.keys(data)).toEqual(['invertTrendColor', 'metric', 'valueLimit']),
      );
    });

    it('does not include metrics that were in excludeMetrics', () => {
      const excludeMetrics = [LEAD_TIME_METRIC_TYPE, CYCLE_TIME_METRIC_TYPE];
      const tableData = generateSkeletonTableData(excludeMetrics);

      const metrics = tableData.map(({ metric }) => metric.identifier);
      expect(metrics).not.toEqual(expect.arrayContaining(excludeMetrics));
    });
  });

  describe('generateMetricComparisons', () => {
    const timePeriods = [
      mockMonthToDateTimePeriod,
      mockPreviousMonthTimePeriod,
      mockTwoMonthsAgoTimePeriod,
      mockThreeMonthsAgoTimePeriod,
    ];

    it('calculates the changes between the 2 time periods', () => {
      const tableData = generateMetricComparisons(timePeriods);
      expect(tableData).toEqual(mockGeneratedMetricComparisons());
    });

    it('returns the comparison table fields + metadata for each row', () => {
      Object.values(generateMetricComparisons(timePeriods)).forEach((row) => {
        expect(row).toMatchObject({
          thisMonth: expect.any(Object),
          lastMonth: expect.any(Object),
          twoMonthsAgo: expect.any(Object),
        });
      });
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

      it('excludes missing metrics from the result', () => {
        expect(res).toEqual(mockSubsetChartData);
      });
    });
  });

  describe('mergeTableData', () => {
    it('correctly integrates existing and new data', () => {
      const newData = { chart: { data: [1, 2, 3] }, lastMonth: { test: 'test' } };
      const rowNoData = { metric: { identifier: 'noData' } };
      const rowWithData = { metric: { identifier: 'withData' } };

      expect(mergeTableData([rowNoData, rowWithData], { withData: newData })).toEqual([
        rowNoData,
        { ...rowWithData, ...newData },
      ]);
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

  describe('generateValueStreamDashboardStartDate', () => {
    it('will return a date', () => {
      expect(generateValueStreamDashboardStartDate()).toBeInstanceOf(Date);
    });

    describe('default', () => {
      useFakeDate(2020, 4, 4);

      it('will return the correct day', () => {
        expect(generateValueStreamDashboardStartDate().toISOString()).toBe(
          '2020-05-04T00:00:00.000Z',
        );
      });
    });

    describe('on the first day of a month', () => {
      useFakeDate(2023, 6, 1);

      it('will return the previous day', () => {
        expect(generateValueStreamDashboardStartDate().toISOString()).toBe(
          '2023-06-30T00:00:00.000Z',
        );
      });
    });
  });

  describe('groupDoraPerformanceScoreCountsByCategory', () => {
    it('returns an object with all of the DORA performance score counts with the category as key', () => {
      const grouped = groupDoraPerformanceScoreCountsByCategory(
        mockDoraPerformersScoreResponseData,
      );

      expect(grouped).toEqual({
        [DORA_PERFORMERS_SCORE_CATEGORY_TYPES.HIGH]: [86, 75, 15, 5],
        [DORA_PERFORMERS_SCORE_CATEGORY_TYPES.MEDIUM]: [24, 30, 55, 70],
        [DORA_PERFORMERS_SCORE_CATEGORY_TYPES.LOW]: [27, 25, 80, 81],
        [DORA_PERFORMERS_SCORE_CATEGORY_TYPES.NO_DATA]: [1, 1, 1, 1],
      });
    });

    it('returns an object with DORA performance score categories as keys and empty arrays as values when given an empty array', () => {
      const grouped = groupDoraPerformanceScoreCountsByCategory([]);

      expect(grouped).toEqual({
        [DORA_PERFORMERS_SCORE_CATEGORY_TYPES.HIGH]: [],
        [DORA_PERFORMERS_SCORE_CATEGORY_TYPES.MEDIUM]: [],
        [DORA_PERFORMERS_SCORE_CATEGORY_TYPES.LOW]: [],
        [DORA_PERFORMERS_SCORE_CATEGORY_TYPES.NO_DATA]: [],
      });
    });
  });
});
