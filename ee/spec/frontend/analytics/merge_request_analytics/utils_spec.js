import * as utils from 'ee/analytics/merge_request_analytics/utils';
import { EXCLUDED_DATA_KEYS } from 'ee/analytics/merge_request_analytics/constants';
import { useFakeDate } from 'helpers/fake_date';
import {
  expectedMonthData,
  throughputChartData,
  formattedThroughputChartData,
  throughputChartNoData,
  formattedMttmData,
  formattedMttmNoData,
} from './mock_data';

describe('computeMonthRangeData', () => {
  const start = new Date('2020-05-17T00:00:00.000Z');
  const end = new Date('2020-07-17T00:00:00.000Z');

  it('returns the data as expected', () => {
    const monthData = utils.computeMonthRangeData(start, end);

    expect(monthData).toStrictEqual(expectedMonthData);
  });

  it('returns an empty array on an invalid date range', () => {
    const monthData = utils.computeMonthRangeData(end, start);

    expect(monthData).toStrictEqual([]);
  });
});

describe('formatThroughputChartData', () => {
  it('returns the data as expected', () => {
    const chartData = utils.formatThroughputChartData(throughputChartData);

    expect(chartData).toStrictEqual(formattedThroughputChartData);
  });

  it('returns an empty array if no data is passed to the util', () => {
    const chartData = utils.formatThroughputChartData();

    expect(chartData).toStrictEqual([]);
  });

  it('excludes items in `EXCLUDED_DATA_KEYS`', () => {
    const [chartData] = utils.formatThroughputChartData(throughputChartData);

    chartData.data.forEach((item) => {
      expect(EXCLUDED_DATA_KEYS).not.toContain(item[0].trim());
    });
  });
});

describe('computeMttmData', () => {
  it('returns the data as expected', () => {
    const mttmData = utils.computeMttmData(throughputChartData);

    expect(mttmData).toStrictEqual(formattedMttmData);
  });

  it('with no time to merge data', () => {
    const mttmData = utils.computeMttmData(throughputChartNoData);

    expect(mttmData).toStrictEqual(formattedMttmNoData);
  });
});

describe('parseAndValidateDates', () => {
  useFakeDate('2021-01-21');

  it.each`
    scenario                                                         | startDateParam  | endDateParam    | expected
    ${'returns the default range if not specified'}                  | ${''}           | ${''}           | ${{ startDate: new Date('2020-01-22'), endDate: new Date('2021-01-21') }}
    ${'returns the dates specified if in range'}                     | ${'2020-06-22'} | ${'2021-01-10'} | ${{ startDate: new Date('2020-06-22'), endDate: new Date('2021-01-10') }}
    ${'returns the default range if dates are out of bounds'}        | ${'2018-06-22'} | ${'2021-01-16'} | ${{ startDate: new Date('2020-01-22'), endDate: new Date('2021-01-21') }}
    ${'returns the default range startDate is greater than endDate'} | ${'2021-01-22'} | ${'2020-06-12'} | ${{ startDate: new Date('2020-01-22'), endDate: new Date('2021-01-21') }}
  `('$scenario', ({ startDateParam, endDateParam, expected }) => {
    const dates = utils.parseAndValidateDates(startDateParam, endDateParam);

    expect(dates).toEqual(expect.objectContaining(expected));
  });
});
