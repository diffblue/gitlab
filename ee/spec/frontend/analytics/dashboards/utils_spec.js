import {
  formatPercentChange,
  formatMetricString,
  extractDoraMetrics,
  generateDoraTimePeriodComparisonTable,
} from 'ee/analytics/dashboards/utils';
import {
  DEPLOYMENT_FREQUENCY_METRIC_TYPE,
  CHANGE_FAILURE_RATE,
  LEAD_TIME_FOR_CHANGES,
  TIME_TO_RESTORE_SERVICE,
} from 'ee/api/dora_api';
import {
  mockCurrentTimePeriod,
  mockPreviousTimePeriod,
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
      ${LEAD_TIME_FOR_CHANGES}   | ${0.2} | ${'0.2/d'}
      ${TIME_TO_RESTORE_SERVICE} | ${0.4} | ${'0.4/d'}
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
      res = generateDoraTimePeriodComparisonTable({
        current: mockCurrentTimePeriod,
        previous: mockPreviousTimePeriod,
      });
    });

    it('returns the comparison table fields for each row', () => {
      res.forEach((row) => {
        expect(Object.keys(row)).toEqual(['metric', 'current', 'previous', 'change']);
      });
    });

    it('calculates the changes between the 2 time periods', () => {
      const formattedValues = mockComparativeTableData.map(({ current, previous, ...rest }) => ({
        ...rest,
        current: current.replace(' days', '/d').replace('/day', '/d'),
        previous: previous.replace(' days', '/d').replace('/day', '/d'),
      }));

      expect(res).toEqual(formattedValues);
    });
  });

  describe('extractDoraMetrics', () => {
    let res = {};
    beforeEach(() => {
      res = extractDoraMetrics(mockMetricsResponse);
    });

    it('returns an object with each of the four DORA metrics', () => {
      expect(Object.keys(res)).toEqual([
        'lead_time_for_changes',
        'change_failure_rate',
        'time_to_restore_service',
        'deployment_frequency',
      ]);
    });

    it('returns the data for each DORA metric', () => {
      expect(res).toEqual(mockCurrentTimePeriod);
      expect(extractDoraMetrics([])).toEqual({});
    });
  });
});
