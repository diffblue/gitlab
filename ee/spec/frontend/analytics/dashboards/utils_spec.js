import {
  formatPercentChange,
  formatMetricString,
  extractDoraMetrics,
  hasDoraMetricValues,
  generateDoraTimePeriodComparisonTable,
} from 'ee/analytics/dashboards/utils';
import {
  DEPLOYMENT_FREQUENCY_METRIC_TYPE,
  CHANGE_FAILURE_RATE,
  LEAD_TIME_FOR_CHANGES,
  TIME_TO_RESTORE_SERVICE,
} from 'ee/api/dora_api';
import {
  mockMonthToDate,
  mockMonthToDateTimePeriod,
  mockPreviousMonthTimePeriod,
  mockTwoMonthsAgoTimePeriod,
  mockComparativeTableData,
  mockMetricsResponse,
} from './mock_data';

describe('Analytics Dashboards utils', () => {
  describe('formatMetricString', () => {
    it.each`
      identifier                          | value   | unit      | result
      ${DEPLOYMENT_FREQUENCY_METRIC_TYPE} | ${19.9} | ${'/day'} | ${'19.9/d'}
      ${CHANGE_FAILURE_RATE}              | ${8.54} | ${'%'}    | ${'8.54%'}
    `('formats $identifier with no space', ({ identifier, value, unit, result }) => {
      expect(formatMetricString({ identifier, value, unit })).toBe(result);
    });

    it.each`
      identifier                 | value  | result
      ${LEAD_TIME_FOR_CHANGES}   | ${0.2} | ${'0.2 d'}
      ${TIME_TO_RESTORE_SERVICE} | ${0.4} | ${'0.4 d'}
    `('formats $identifier with a space', ({ identifier, value, result }) => {
      expect(formatMetricString({ identifier, value, unit: 'days' })).toBe(result);
    });
  });

  describe('formatPercentChange', () => {
    it.each`
      current  | previous | result
      ${10}    | ${20}    | ${'-50%'}
      ${2.93}  | ${5}     | ${'-41.4%'}
      ${8.394} | ${2.324} | ${'261.19%'}
      ${5}     | ${0}     | ${'-'}
    `('calculates the percentage change given 2 numbers', ({ current, previous, result }) => {
      expect(formatPercentChange({ current, previous })).toBe(result);
    });

    it.each`
      current | previous | precision    | result
      ${10}   | ${2.32}  | ${5}         | ${'331.03448%'}
      ${2.93} | ${5.37}  | ${undefined} | ${'-45.44%'}
    `('defaults to 2 decimal places', ({ current, previous, precision, result }) => {
      expect(formatPercentChange({ current, previous, precision })).toBe(result);
    });
  });

  describe('generateDoraTimePeriodComparisonTable', () => {
    let res = {};

    beforeEach(() => {
      res = generateDoraTimePeriodComparisonTable([
        mockMonthToDateTimePeriod,
        mockPreviousMonthTimePeriod,
        mockTwoMonthsAgoTimePeriod,
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

  describe('extractDoraMetrics', () => {
    let res = {};
    beforeEach(() => {
      res = extractDoraMetrics(mockMetricsResponse);
    });

    it('returns an object with each of the four DORA metrics', () => {
      expect(Object.keys(res)).toEqual([
        LEAD_TIME_FOR_CHANGES,
        TIME_TO_RESTORE_SERVICE,
        CHANGE_FAILURE_RATE,
        DEPLOYMENT_FREQUENCY_METRIC_TYPE,
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
