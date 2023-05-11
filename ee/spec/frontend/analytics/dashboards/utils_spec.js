import { stringify } from 'yaml';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_NOT_FOUND, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { VULNERABILITY_CRITICAL_TYPE, VULNERABILITY_HIGH_TYPE } from '~/analytics/shared/constants';
import { UNITS } from 'ee/analytics/dashboards/constants';
import {
  fetchYamlConfig,
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
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('fetchYamlConfig', () => {
    const YAML_PROJECT_ID = 1337;
    const API_PATH = /\/api\/(.*)\/projects\/(.*)\/repository\/files\/\.gitlab%2Fanalytics%2Fdashboards%2Fvalue_streams%2Fvalue_streams\.ya?ml\/raw/;

    it('returns null if the project ID is falsey', async () => {
      const config = await fetchYamlConfig(null);
      expect(config).toBeNull();
    });

    it('returns null if the file fails to load', async () => {
      mock.onGet(API_PATH).reply(HTTP_STATUS_NOT_FOUND);
      const config = await fetchYamlConfig(YAML_PROJECT_ID);
      expect(config).toBeNull();
    });

    it('returns null if the YAML config fails to parse', async () => {
      mock.onGet(API_PATH).reply(HTTP_STATUS_OK, { data: null });
      const config = await fetchYamlConfig(YAML_PROJECT_ID);
      expect(config).toBeNull();
    });

    it('returns the parsed YAML config on success', async () => {
      const mockConfig = {
        title: 'TITLE',
        description: 'DESC',
        widgets: [{ data: { namespace: 'test/one' } }, { data: { namespace: 'test/two' } }],
      };

      mock.onGet(API_PATH).reply(HTTP_STATUS_OK, stringify(mockConfig));
      const config = await fetchYamlConfig(YAML_PROJECT_ID);
      expect(config).toEqual(mockConfig);
    });
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
        VULNERABILITY_CRITICAL_TYPE,
        VULNERABILITY_HIGH_TYPE,
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
