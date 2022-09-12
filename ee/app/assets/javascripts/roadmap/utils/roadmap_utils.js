import { getTimeframeWindowFrom, newDate, totalDaysInMonth } from '~/lib/utils/datetime_utility';

import { DAYS_IN_WEEK, DATE_RANGES, PRESET_TYPES } from '../constants';

const monthsForQuarters = {
  1: [0, 1, 2],
  2: [3, 4, 5],
  3: [6, 7, 8],
  4: [9, 10, 11],
};

export const getFirstDay = () => {
  return window?.gon?.first_day_of_week ?? 0;
};

export const getWeeksForDates = (startDate, endDate) => {
  const timeframe = [];
  const start = newDate(startDate);
  const end = newDate(endDate);

  // Move to Sunday that comes just before startDate
  start.setDate(start.getDate() - start.getDay() + getFirstDay());

  while (start.getTime() < end.getTime()) {
    // Push date to timeframe only when day is
    // first day (Sunday) of the week
    timeframe.push(newDate(start));

    // Move date next Sunday
    start.setDate(start.getDate() + DAYS_IN_WEEK);
  }

  return timeframe;
};

export const getMonthsForDates = (startDate, endDate) => {
  const timeframe = [];
  const start = newDate(startDate);
  const end = newDate(endDate);

  while (start.getTime() < end.getTime()) {
    timeframe.push(newDate(start));
    start.setMonth(start.getMonth() + 1);
  }

  return timeframe;
};

export const getTimeframeForRangeType = ({
  timeframeRangeType = DATE_RANGES.CURRENT_QUARTER,
  presetType = PRESET_TYPES.WEEKS,
  initialDate = new Date(),
}) => {
  let timeframe = [];
  const startDate = newDate(initialDate);
  startDate.setHours(0, 0, 0, 0);

  // We need to prepare timeframe containing all the weeks of
  // current quarter.
  if (timeframeRangeType === DATE_RANGES.CURRENT_QUARTER) {
    // Get current quarter for current month
    const currentQuarter = Math.floor((startDate.getMonth() + 3) / 3);
    // Get index of current month in current quarter
    // It could be 0, 1, 2 (i.e. first, second or third)
    const currentMonthInCurrentQuarter = monthsForQuarters[currentQuarter].indexOf(
      startDate.getMonth(),
    );

    // Get last day of the last month of current quarter
    const endDate = newDate(startDate);
    if (currentMonthInCurrentQuarter === 0) {
      endDate.setMonth(endDate.getMonth() + 2);
    } else if (currentMonthInCurrentQuarter === 1) {
      endDate.setMonth(endDate.getMonth() + 1);
    }
    endDate.setDate(totalDaysInMonth(endDate));

    // Move startDate to first day of the first month of current quarter
    startDate.setMonth(startDate.getMonth() - currentMonthInCurrentQuarter);
    startDate.setDate(1);

    timeframe = getWeeksForDates(startDate, endDate);
  } else if (timeframeRangeType === DATE_RANGES.CURRENT_YEAR) {
    // Move start date to first day of current year
    startDate.setMonth(0);
    startDate.setDate(1);

    if (presetType === PRESET_TYPES.MONTHS) {
      timeframe = getTimeframeWindowFrom(startDate, 12);
    } else {
      // Get last day of current year
      const endDate = newDate(startDate);
      endDate.setMonth(11);
      endDate.setDate(totalDaysInMonth(endDate));

      timeframe = getWeeksForDates(startDate, endDate);
    }
  } else {
    // Get last day of the month, 18 months from startDate.
    const endDate = newDate(startDate);
    endDate.setMonth(endDate.getMonth() + 18);
    endDate.setDate(totalDaysInMonth(endDate));

    // Move start date to the 18 months behind
    startDate.setMonth(startDate.getMonth() - 18);
    startDate.setDate(1);

    if (presetType === PRESET_TYPES.QUARTERS) {
      // Shift start and end dates to align with calender quarters
      startDate.setMonth(startDate.getMonth() - (startDate.getMonth() % 3));
      endDate.setMonth(endDate.getMonth() + (2 - (endDate.getMonth() % 3)));

      timeframe = getMonthsForDates(startDate, endDate);
      const quartersTimeframe = [];

      // Iterate over the timeframe and break it down
      // in chunks of quarters
      for (let i = 0; i < timeframe.length; i += 3) {
        const range = timeframe.slice(i, i + 3);
        const lastMonthOfQuarter = range[range.length - 1];
        const quarterSequence = Math.floor((range[0].getMonth() + 3) / 3);
        const year = range[0].getFullYear();

        // Ensure that `range` spans across duration of
        // entire quarter
        lastMonthOfQuarter.setDate(totalDaysInMonth(lastMonthOfQuarter));

        quartersTimeframe.push({
          quarterSequence,
          range,
          year,
        });
      }
      timeframe = quartersTimeframe;
    } else if (presetType === PRESET_TYPES.MONTHS) {
      timeframe = getTimeframeWindowFrom(startDate, 18 * 2);
    } else {
      timeframe = getWeeksForDates(startDate, endDate);
    }
  }

  return timeframe;
};

/**
 * Returns timeframe range in string based on provided config.
 *
 * @param {object} config
 * @param {string} config.presetType String representing preset type
 * @param {array} config.timeframe Array of dates representing timeframe
 *
 * @returns {object} Returns an object containing `startDate` & `dueDate` strings
 *                   Computed using presetType and timeframe.
 */
export const getEpicsTimeframeRange = ({ presetType = '', timeframe = [] }) => {
  let start;
  let due;

  const firstTimeframe = timeframe[0];
  const lastTimeframe = timeframe[timeframe.length - 1];
  // Compute start and end dates from timeframe
  // based on provided presetType.
  if (presetType === PRESET_TYPES.QUARTERS) {
    [start] = firstTimeframe.range;
    due = lastTimeframe.range[lastTimeframe.range.length - 1];
  } else if (presetType === PRESET_TYPES.MONTHS) {
    start = firstTimeframe;
    due = lastTimeframe;
  } else if (presetType === PRESET_TYPES.WEEKS) {
    start = firstTimeframe;
    due = newDate(lastTimeframe);
    due.setDate(due.getDate() + 6);
  }

  return {
    timeframe: {
      start: start.toISOString().split('T')[0],
      end: due.toISOString().split('T')[0],
    },
  };
};

export const sortEpics = (epics, sortedBy) => {
  const sortByStartDate = sortedBy.indexOf('start_date') > -1;
  const sortOrderAsc = sortedBy.indexOf('asc') > -1;

  epics.sort((a, b) => {
    let aDate;
    let bDate;

    if (sortByStartDate) {
      // Always use the original start date.
      // if originalStartDate exists, it means startDate was changed to a proxy date
      // (refer to roadmap_item_utils.js)
      const startDateForA = a.originalStartDate ? a.originalStartDate : a.startDate;
      const startDateForB = b.originalStartDate ? b.originalStartDate : b.startDate;

      // When epic has no fixed start date, use Number.NEGATIVE_INFINITY for comparison.
      // In other words, epics without fixed start date should, in theory, have the earliest start date.
      // (the actual min possible value for Date object is much smaller; ECMA-262 20.4.1.1)
      aDate = a.startDateUndefined ? Number.NEGATIVE_INFINITY : startDateForA.getTime();
      bDate = b.startDateUndefined ? Number.NEGATIVE_INFINITY : startDateForB.getTime();
    } else {
      const endDateForA = a.originalEndDate ? a.originalEndDate : a.endDate;
      const endDateForB = b.originalEndDate ? b.originalEndDate : b.endDate;

      // Similarly, use Infinity when epic has no fixed due date.
      aDate = a.endDateUndefined ? Infinity : endDateForA.getTime();
      bDate = b.endDateUndefined ? Infinity : endDateForB.getTime();
    }

    // Sort in ascending or descending order
    if (aDate < bDate) {
      return sortOrderAsc ? -1 : 1;
    } else if (aDate > bDate) {
      return sortOrderAsc ? 1 : -1;
    }
    return 0;
  });
};

export const getPresetTypeForTimeframeRangeType = (timeframeRangeType, initialPresetType) => {
  let presetType;
  switch (timeframeRangeType) {
    case DATE_RANGES.CURRENT_QUARTER:
      presetType = PRESET_TYPES.WEEKS;
      break;
    case DATE_RANGES.CURRENT_YEAR:
      presetType = [PRESET_TYPES.MONTHS, PRESET_TYPES.WEEKS].includes(initialPresetType)
        ? initialPresetType
        : PRESET_TYPES.MONTHS;
      break;
    case DATE_RANGES.THREE_YEARS:
      presetType = [PRESET_TYPES.QUARTERS, PRESET_TYPES.MONTHS, PRESET_TYPES.WEEKS].includes(
        initialPresetType,
      )
        ? initialPresetType
        : PRESET_TYPES.QUARTERS;
      break;
    default:
      break;
  }
  return presetType;
};
