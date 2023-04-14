import {
  buildDefaultDashboardFilters,
  dateRangeOptionToFilter,
  filtersToQueryParams,
  getDateRangeOption,
  isEmptyPanelData,
} from 'ee/vue_shared/components/customizable_dashboard/utils';
import { parsePikadayDate } from '~/lib/utils/datetime_utility';
import {
  CUSTOM_DATE_RANGE_KEY,
  DATE_RANGE_OPTIONS,
  DEFAULT_SELECTED_OPTION_INDEX,
} from 'ee/vue_shared/components/customizable_dashboard/filters/constants';
import { mockDateRangeFilterChangePayload } from './mock_data';

const option = DATE_RANGE_OPTIONS[0];

describe('getDateRangeOption', () => {
  it('should return the date range option', () => {
    expect(getDateRangeOption(option.key)).toStrictEqual(option);
  });
});

describe('dateRangeOptionToFilter', () => {
  it('filters data by `name` for the provided search term', () => {
    expect(dateRangeOptionToFilter(option)).toStrictEqual({
      startDate: option.startDate,
      endDate: option.endDate,
      dateRangeOption: option.key,
    });
  });
});

describe('buildDefaultDashboardFilters', () => {
  it('returns the default option for an empty query string', () => {
    const defaultOption = DATE_RANGE_OPTIONS[DEFAULT_SELECTED_OPTION_INDEX];

    expect(buildDefaultDashboardFilters('')).toStrictEqual({
      startDate: defaultOption.startDate,
      endDate: defaultOption.endDate,
      dateRangeOption: defaultOption.key,
    });
  });

  it('returns the option that matches the date_range_option', () => {
    const queryString = `date_range_option=${option.key}`;

    expect(buildDefaultDashboardFilters(queryString)).toStrictEqual({
      startDate: option.startDate,
      endDate: option.endDate,
      dateRangeOption: option.key,
    });
  });

  it('returns the a custom range when the query string is custom and contains dates', () => {
    const queryString = `date_range_option=${CUSTOM_DATE_RANGE_KEY}&start_date=2023-01-10&end_date=2023-02-08`;

    expect(buildDefaultDashboardFilters(queryString)).toStrictEqual({
      startDate: parsePikadayDate('2023-01-10'),
      endDate: parsePikadayDate('2023-02-08'),
      dateRangeOption: CUSTOM_DATE_RANGE_KEY,
    });
  });

  it('returns the option that matches the date_range_option and ignores the query dates when the option is not custom', () => {
    const queryString = `date_range_option=${option.key}&start_date=2023-01-10&end_date=2023-02-08`;

    expect(buildDefaultDashboardFilters(queryString)).toStrictEqual({
      startDate: option.startDate,
      endDate: option.endDate,
      dateRangeOption: option.key,
    });
  });
});

describe('filtersToQueryParams', () => {
  const customOption = {
    ...mockDateRangeFilterChangePayload,
    dateRangeOption: CUSTOM_DATE_RANGE_KEY,
  };

  const nonCustomOption = {
    ...mockDateRangeFilterChangePayload,
    dateRangeOption: 'foobar',
  };

  it('returns the dateRangeOption with null date params when the option is not custom', () => {
    expect(filtersToQueryParams(nonCustomOption)).toStrictEqual({
      date_range_option: 'foobar',
      end_date: null,
      start_date: null,
    });
  });

  it('returns the dateRangeOption and date params when the option is custom', () => {
    expect(filtersToQueryParams(customOption)).toStrictEqual({
      date_range_option: CUSTOM_DATE_RANGE_KEY,
      start_date: '2016-01-01',
      end_date: '2016-02-01',
    });
  });
});

describe('isEmptyPanelData', () => {
  it.each`
    visualizationType | value  | expected
    ${'SingleStat'}   | ${[]}  | ${false}
    ${'SingleStat'}   | ${1}   | ${false}
    ${'LineChart'}    | ${[]}  | ${true}
    ${'LineChart'}    | ${[1]} | ${false}
  `(
    'returns $expected for visualization "$visualizationType" with value "$value"',
    ({ visualizationType, value, expected }) => {
      const result = isEmptyPanelData(visualizationType, value);
      expect(result).toBe(expected);
    },
  );
});
