import lastWeekData from 'test_fixtures/api/dora/metrics/daily_lead_time_for_changes_for_last_week.json';
import deploymentFrequencyLastWeekData from 'test_fixtures/api/dora/metrics/daily_deployment_frequency_for_last_week.json';
import { buildNullSeries } from 'ee/analytics/shared/utils';
import {
  apiDataToChartSeries,
  seriesToAverageSeries,
  seriesToMedianSeries,
  extractTimeSeriesTooltip,
  secondsToDays,
  formatAsPercentage,
  forecastDataToSeries,
  calculateForecast,
} from 'ee/dora/components/util';
import * as utils from 'ee/analytics/shared/utils';
import * as graphQLApi from 'ee/dora/graphql/api';
import { forecastDataToChartDate } from './helpers';
import { mockLastWeekData, mockLastWeekHoltWintersForecastData } from './mock_data';

const NO_DATA_MESSAGE = 'No data available';

describe('ee/dora/components/util.js', () => {
  describe('apiDataToChartSeries', () => {
    it('transforms the data from the API into data the chart component can use', () => {
      const apiData = [
        // This is the date format we expect from the API
        { value: 5, date: '2015-06-28' },

        // But we should support _any_ date format
        { value: 1, date: '2015-06-28T20:00:00.000-0400' },
        { value: 8, date: '2015-07-01T00:00:00.000Z' },
      ];

      const startDate = new Date(2015, 5, 26, 10);
      const endDate = new Date(2015, 6, 4, 10);
      const chartTitle = 'Chart title';

      const expected = [
        {
          name: chartTitle,
          data: [
            ['Jun 26', 0],
            ['Jun 27', 0],
            ['Jun 28', 5],
            ['Jun 29', 1],
            ['Jun 30', 0],
            ['Jul 1', 8],
            ['Jul 2', 0],
            ['Jul 3', 0],
          ],
        },
      ];

      expect(apiDataToChartSeries(apiData, startDate, endDate, chartTitle)).toEqual(expected);
    });
  });

  describe('lead time data', () => {
    it('returns the correct lead time chart data after all processing of the API response', () => {
      const chartData = buildNullSeries({
        seriesData: apiDataToChartSeries(
          lastWeekData,
          new Date(2015, 5, 27, 10),
          new Date(2015, 6, 4, 10),
          'Lead time',
          null,
        ),
        nullSeriesTitle: NO_DATA_MESSAGE,
      });

      expect(chartData).toMatchSnapshot();
    });
  });

  describe('seriesToAverageSeries', () => {
    const seriesName = 'Average';

    it('returns an empty object if chart data is undefined', () => {
      const data = seriesToAverageSeries(undefined, seriesName);

      expect(data).toStrictEqual({});
    });

    it('returns an empty object if chart data is blank', () => {
      const data = seriesToAverageSeries(null, seriesName);

      expect(data).toStrictEqual({});
    });

    it('returns the correct average values', () => {
      const data = seriesToAverageSeries(
        [
          ['Jul 1', 2],
          ['Jul 2', 3],
          ['Jul 3', 4],
        ],
        seriesName,
      );

      expect(data).toStrictEqual({
        name: seriesName,
        data: [
          ['Jul 1', 3],
          ['Jul 2', 3],
          ['Jul 3', 3],
        ],
      });
    });
  });

  describe('seriesToMedianSeries', () => {
    const seriesName = 'Median';

    it('returns an empty object if chart data is undefined', () => {
      const data = seriesToMedianSeries(undefined, seriesName);

      expect(data).toStrictEqual({});
    });

    it('returns an empty object if chart data is blank', () => {
      const data = seriesToMedianSeries(null, seriesName);

      expect(data).toStrictEqual({});
    });

    it('returns the correct median values', () => {
      const data = seriesToMedianSeries(
        [
          ['Jul 1', 1],
          ['Jul 2', 3],
          ['Jul 3', 10],
        ],
        seriesName,
      );

      expect(data).toStrictEqual({
        name: seriesName,
        data: [
          ['Jul 1', 3],
          ['Jul 2', 3],
          ['Jul 3', 3],
        ],
      });
    });
  });

  describe('extractTimeSeriesTooltip', () => {
    const fakeChartTitle = 'cool-chart-title';
    const params = { seriesData: [{ data: ['Apr 7', 5328] }, { data: ['Apr 7', 4000] }, {}] };

    it('displays a humanized version of the time interval in the tooltip', () => {
      const { tooltipValue } = extractTimeSeriesTooltip(params, fakeChartTitle);

      expect(tooltipValue[0].value).toBe('1.5 hours');
      expect(tooltipValue[1].value).toBe('1.1 hours');
    });

    it('will apply a custom formatter when supplied', () => {
      const formatter = jest.fn();

      extractTimeSeriesTooltip(params, fakeChartTitle, formatter);
      expect(formatter).toHaveBeenCalledTimes(2);
    });
  });

  describe('secondsToDays', () => {
    const seconds = 151000;

    it('defaults to a single decimal', () => {
      expect(secondsToDays(seconds)).toBe('1.7');
    });

    it('will format to the specified precision', () => {
      expect(secondsToDays(seconds, 3)).toBe('1.748');
    });
  });

  describe('formatAsPercentage', () => {
    it('returns 0 if given NaN', () => {
      expect(formatAsPercentage(null)).toBe('0.0%');
      expect(formatAsPercentage('a')).toBe('0.0%');
    });

    it('formats valid values', () => {
      expect(formatAsPercentage(0.25)).toBe('25.0%');
      expect(formatAsPercentage('1.86', 0)).toBe('186%');
    });
  });

  describe('forecastDataToSeries', () => {
    let res;

    const forecastResponse = forecastDataToChartDate(
      deploymentFrequencyLastWeekData,
      mockLastWeekHoltWintersForecastData,
    );

    beforeEach(() => {
      res = forecastDataToSeries({
        forecastData: mockLastWeekHoltWintersForecastData,
        forecastHorizon: 3,
        forecastSeriesLabel: 'Forecast',
        dataSeries: mockLastWeekData,
        endDate: new Date('2015-07-04'),
      });
    });

    it('returns the data data series to be displayed in charts', () => {
      expect(res).toEqual(forecastResponse);
    });

    it('includes the last data point from the data series', () => {
      expect(res[0]).toEqual(['Jul 3', 1]);
    });
  });

  describe('calculateForecast', () => {
    let buildForecastSpy;
    let linearRegressionSpy;

    const contextId = 'gid://gitlab/project/1';
    const forecastHorizon = 3;
    const rawApiData = [];
    const defaultParams = { contextId, forecastHorizon, rawApiData };

    describe('with `useHoltWintersForecast=true`', () => {
      beforeEach(() => {
        buildForecastSpy = jest.spyOn(graphQLApi, 'buildForecast').mockReturnValue();
        calculateForecast({ ...defaultParams, useHoltWintersForecast: true });
      });

      it('will call the `buildForecast` api request', () => {
        expect(buildForecastSpy).toHaveBeenCalledWith(contextId, forecastHorizon);
      });
    });

    describe('with `useHoltWintersForecast=false`', () => {
      beforeEach(() => {
        linearRegressionSpy = jest.spyOn(utils, 'linearRegression');
        calculateForecast({ ...defaultParams, useHoltWintersForecast: false });
      });

      it('will generate a linear regression request', () => {
        expect(linearRegressionSpy).toHaveBeenCalledWith(rawApiData, forecastHorizon);
      });
    });
  });
});
