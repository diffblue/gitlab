import { PRESET_TYPES, DATE_RANGES } from 'ee/roadmap/constants';
import {
  getEpicsTimeframeRange,
  getMonthsForDates,
  getPresetTypeForTimeframeRangeType,
  getTimeframeForRangeType,
  getLocaleOffsetDays,
  getWeeksForDates,
  sortEpics,
} from 'ee/roadmap/utils/roadmap_utils';

import { mockTimeframeInitialDate, mockUnsortedEpics } from '../mock_data';

const mockTimeframeMonths = getTimeframeForRangeType({
  timeframeRangeType: DATE_RANGES.CURRENT_YEAR,
  presetType: PRESET_TYPES.MONTHS,
  initialDate: mockTimeframeInitialDate,
});
const getDateString = (date) => date.toISOString().split('T')[0];

describe('getLocaleOffsetDays', () => {
  it.each`
    firstDayName  | firstDayOfWeek | localeOffsetDays
    ${'Saturday'} | ${6}           | ${2}
    ${'Sunday'}   | ${0}           | ${1}
    ${'Monday'}   | ${1}           | ${0}
  `(
    'returns $localeOffsetDays when first day of week is $firstDayName',
    ({ firstDayOfWeek, localeOffsetDays }) => {
      window.gon.first_day_of_week = firstDayOfWeek;

      expect(getLocaleOffsetDays()).toBe(localeOffsetDays);
    },
  );
});

describe('getWeeksForDates', () => {
  it('returns weeks for given dates', () => {
    const weeks = getWeeksForDates(mockTimeframeInitialDate, mockTimeframeMonths[4]);

    expect(weeks).toHaveLength(18);
    expect(getDateString(weeks[0])).toBe('2017-12-31');
    expect(getDateString(weeks[7])).toBe('2018-02-18');
    expect(getDateString(weeks[17])).toBe('2018-04-29');
  });

  describe('when different first day of week', () => {
    beforeEach(() => {
      window.gon.first_day_of_week = 1;
    });

    it('returns correct weeks', () => {
      const weeks = getWeeksForDates(mockTimeframeInitialDate, mockTimeframeMonths[4]);

      expect(weeks).toHaveLength(18);
      expect(getDateString(weeks[0])).toBe('2018-01-01');
      expect(getDateString(weeks[7])).toBe('2018-02-19');
      expect(getDateString(weeks[17])).toBe('2018-04-30');
    });
  });
});

describe('getMonthsForDates', () => {
  it('returns months for given start and due dates', () => {
    const months = getMonthsForDates(mockTimeframeInitialDate, mockTimeframeMonths[4]);

    expect(months).toHaveLength(4);
    const dates = ['2018-01-01', '2018-02-01', '2018-03-01', '2018-04-01'];
    dates.forEach((date, index) => {
      expect(getDateString(months[index])).toBe(date);
    });
  });
});

describe('getTimeframeForRangeType', () => {
  beforeEach(() => {
    jest.useFakeTimers({ legacyFakeTimers: false });
    jest.setSystemTime(new Date('2021-01-01'));
  });

  afterEach(() => {
    jest.useFakeTimers({ legacyFakeTimers: true });
    jest.runOnlyPendingTimers();
  });

  it('returns timeframe with weeks when timeframeRangeType is current quarter', () => {
    const timeframe = getTimeframeForRangeType({ timeframeRangeType: DATE_RANGES.CURRENT_QUARTER });

    expect(timeframe).toHaveLength(14);
    expect(getDateString(timeframe[0])).toBe('2020-12-27');
    expect(getDateString(timeframe[6])).toBe('2021-02-07');
    expect(getDateString(timeframe[13])).toBe('2021-03-28');
  });

  it('returns timeframe with months when timeframeRangeType is current year and preset type is months', () => {
    const timeframe = getTimeframeForRangeType({
      timeframeRangeType: DATE_RANGES.CURRENT_YEAR,
      presetType: PRESET_TYPES.MONTHS,
    });

    expect(timeframe).toHaveLength(12);
    expect(getDateString(timeframe[0])).toBe('2021-01-01');
    expect(getDateString(timeframe[5])).toBe('2021-06-01');
    expect(getDateString(timeframe[11])).toBe('2021-12-31');
  });

  it('returns timeframe with weeks when timeframeRangeType is current year', () => {
    const timeframe = getTimeframeForRangeType({
      timeframeRangeType: DATE_RANGES.CURRENT_YEAR,
      presetType: PRESET_TYPES.WEEKS,
    });

    expect(timeframe).toHaveLength(53);
    expect(getDateString(timeframe[0])).toBe('2020-12-27');
    expect(getDateString(timeframe[25])).toBe('2021-06-20');
    expect(getDateString(timeframe[52])).toBe('2021-12-26');
  });

  it('returns timeframe with quarters when timeframeRangeType is within 3 years', () => {
    const timeframe = getTimeframeForRangeType({
      timeframeRangeType: DATE_RANGES.THREE_YEARS,
      presetType: PRESET_TYPES.QUARTERS,
    });

    expect(timeframe).toHaveLength(13);

    expect(timeframe[0]).toMatchObject({
      quarterSequence: 3,
      year: 2019,
      range: expect.any(Array),
    });
    expect(getDateString(timeframe[0].range[0])).toBe('2019-07-01');
    expect(getDateString(timeframe[0].range[1])).toBe('2019-08-01');
    expect(getDateString(timeframe[0].range[2])).toBe('2019-09-30');

    expect(timeframe[11]).toMatchObject({
      quarterSequence: 2,
      year: 2022,
      range: expect.any(Array),
    });
    expect(getDateString(timeframe[11].range[0])).toBe('2022-04-01');
    expect(getDateString(timeframe[11].range[1])).toBe('2022-05-01');
    expect(getDateString(timeframe[11].range[2])).toBe('2022-06-30');
  });

  it('returns timeframe with months when timeframeRangeType is within 3 years', () => {
    const timeframe = getTimeframeForRangeType({
      timeframeRangeType: DATE_RANGES.THREE_YEARS,
      presetType: PRESET_TYPES.MONTHS,
    });

    expect(timeframe).toHaveLength(36);

    expect(getDateString(timeframe[0])).toBe('2019-07-01');
    expect(getDateString(timeframe[35])).toBe('2022-06-30');
  });

  it('returns timeframe with weeks when timeframeRangeType is within 3 years', () => {
    const timeframe = getTimeframeForRangeType({
      timeframeRangeType: DATE_RANGES.THREE_YEARS,
      presetType: PRESET_TYPES.WEEKS,
    });

    expect(timeframe).toHaveLength(161);

    expect(getDateString(timeframe[0])).toBe('2019-06-30');
    expect(getDateString(timeframe[160])).toBe('2022-07-24');
  });
});

describe('getEpicsTimeframeRange', () => {
  it('returns object containing startDate and dueDate based on provided timeframe for Quarters', () => {
    const timeframeQuarters = getTimeframeForRangeType({
      timeframeRangeType: DATE_RANGES.THREE_YEARS,
      presetType: PRESET_TYPES.QUARTERS,
      initialDate: new Date(2018, 0, 1),
    });
    const range = getEpicsTimeframeRange({
      presetType: PRESET_TYPES.QUARTERS,
      timeframe: timeframeQuarters,
    });

    expect(range).toEqual(
      expect.objectContaining({
        timeframe: {
          start: '2016-07-01',
          end: '2019-09-30',
        },
      }),
    );
  });

  it('returns object containing startDate and dueDate based on provided timeframe for Months', () => {
    const timeframeMonths = getTimeframeForRangeType({
      timeframeRangeType: DATE_RANGES.CURRENT_YEAR,
      presetType: PRESET_TYPES.MONTHS,
      initialDate: new Date(2018, 0, 1),
    });
    const range = getEpicsTimeframeRange({
      presetType: PRESET_TYPES.MONTHS,
      timeframe: timeframeMonths,
    });

    expect(range).toEqual(
      expect.objectContaining({
        timeframe: {
          start: '2018-01-01',
          end: '2018-12-31',
        },
      }),
    );
  });

  it('returns object containing startDate and dueDate based on provided timeframe for Weeks', () => {
    const timeframeWeeks = getTimeframeForRangeType({
      timeframeRangeType: DATE_RANGES.CURRENT_QUARTER,
      presetType: PRESET_TYPES.WEEKS,
      initialDate: new Date(2018, 0, 1),
    });
    const range = getEpicsTimeframeRange({
      presetType: PRESET_TYPES.WEEKS,
      timeframe: timeframeWeeks,
    });

    expect(range).toEqual(
      expect.objectContaining({
        timeframe: {
          start: '2017-12-31',
          end: '2018-03-31',
        },
      }),
    );
  });
});

describe('sortEpics', () => {
  it('sorts epics list by startDate in ascending order when `sortedBy` param is `start_date_asc`', () => {
    const epics = mockUnsortedEpics.slice();
    const sortedOrder = [
      'Jan 01 2020 ~ Dec 01 2020; no fixed start date',
      'Nov 10 2013 ~ Jun 01 2014; actual start date is Feb 1 2013',
      'Mar 01 2013 ~ Dec 01 2013; no fixed due date',
      'Oct 01 2013 ~ Nov 01 2013; actual due date is Nov 1 2014',
      'Mar 17 2014 ~ Aug 15 2015',
      'Jun 08 2015 ~ Apr 01 2016',
      'Mar 12 2017 ~ Aug 20 2017',
      'Apr 12 2019 ~ Aug 30 2019',
    ];

    sortEpics(epics, 'start_date_asc');

    expect(epics).toHaveLength(mockUnsortedEpics.length);

    epics.forEach((epic, index) => {
      expect(epic.title).toEqual(sortedOrder[index]);
    });
  });

  it('sorts epics list by startDate in descending order when `sortedBy` param is `start_date_desc`', () => {
    const epics = mockUnsortedEpics.slice();
    const sortedOrder = [
      'Apr 12 2019 ~ Aug 30 2019',
      'Mar 12 2017 ~ Aug 20 2017',
      'Jun 08 2015 ~ Apr 01 2016',
      'Mar 17 2014 ~ Aug 15 2015',
      'Oct 01 2013 ~ Nov 01 2013; actual due date is Nov 1 2014',
      'Mar 01 2013 ~ Dec 01 2013; no fixed due date',
      'Nov 10 2013 ~ Jun 01 2014; actual start date is Feb 1 2013',
      'Jan 01 2020 ~ Dec 01 2020; no fixed start date',
    ];

    sortEpics(epics, 'start_date_desc');

    expect(epics).toHaveLength(mockUnsortedEpics.length);

    epics.forEach((epic, index) => {
      expect(epic.title).toEqual(sortedOrder[index]);
    });
  });

  it('sorts epics list by endDate in ascending order when `sortedBy` param is `end_date_asc`', () => {
    const epics = mockUnsortedEpics.slice();
    const sortedOrder = [
      'Nov 10 2013 ~ Jun 01 2014; actual start date is Feb 1 2013',
      'Oct 01 2013 ~ Nov 01 2013; actual due date is Nov 1 2014',
      'Mar 17 2014 ~ Aug 15 2015',
      'Jun 08 2015 ~ Apr 01 2016',
      'Mar 12 2017 ~ Aug 20 2017',
      'Apr 12 2019 ~ Aug 30 2019',
      'Jan 01 2020 ~ Dec 01 2020; no fixed start date',
      'Mar 01 2013 ~ Dec 01 2013; no fixed due date',
    ];

    sortEpics(epics, 'end_date_asc');

    expect(epics).toHaveLength(mockUnsortedEpics.length);

    epics.forEach((epic, index) => {
      expect(epic.title).toEqual(sortedOrder[index]);
    });
  });

  it('sorts epics list by endDate in descending order when `sortedBy` param is `end_date_desc`', () => {
    const epics = mockUnsortedEpics.slice();
    const sortedOrder = [
      'Mar 01 2013 ~ Dec 01 2013; no fixed due date',
      'Jan 01 2020 ~ Dec 01 2020; no fixed start date',
      'Apr 12 2019 ~ Aug 30 2019',
      'Mar 12 2017 ~ Aug 20 2017',
      'Jun 08 2015 ~ Apr 01 2016',
      'Mar 17 2014 ~ Aug 15 2015',
      'Oct 01 2013 ~ Nov 01 2013; actual due date is Nov 1 2014',
      'Nov 10 2013 ~ Jun 01 2014; actual start date is Feb 1 2013',
    ];

    sortEpics(epics, 'end_date_desc');

    expect(epics).toHaveLength(mockUnsortedEpics.length);

    epics.forEach((epic, index) => {
      expect(epic.title).toEqual(sortedOrder[index]);
    });
  });
});

describe('getPresetTypeForTimeframeRangeType', () => {
  it.each`
    timeframeRangeType             | presetType
    ${DATE_RANGES.CURRENT_QUARTER} | ${PRESET_TYPES.WEEKS}
    ${DATE_RANGES.CURRENT_YEAR}    | ${PRESET_TYPES.MONTHS}
    ${DATE_RANGES.THREE_YEARS}     | ${PRESET_TYPES.QUARTERS}
  `(
    'returns presetType as $presetType when $timeframeRangeType',
    ({ timeframeRangeType, presetType }) => {
      expect(getPresetTypeForTimeframeRangeType(timeframeRangeType)).toEqual(presetType);
    },
  );
});
