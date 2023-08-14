import { dateToYearMonthDate, newDateAsLocaleTime } from '~/lib/utils/datetime_utility';

const formatMonthData = (cur) => {
  const date = newDateAsLocaleTime(cur.monthIso8601);
  const formattedDate = dateToYearMonthDate(date);

  return {
    date,
    ...formattedDate,
    ...cur,
  };
};

export const getUsageDataByYearAsArray = (ciMinutesUsage) => {
  return ciMinutesUsage.reduce((acc, cur) => {
    const formattedData = formatMonthData(cur);

    if (acc[formattedData.year] != null) {
      acc[formattedData.year].push(formattedData);
    } else {
      acc[formattedData.year] = [formattedData];
    }
    return acc;
  }, {});
};

export const getUsageDataByYearByMonthAsObject = (ciMinutesUsage) => {
  return ciMinutesUsage.reduce((acc, cur) => {
    const formattedData = formatMonthData(cur);

    if (!acc[formattedData.year]) {
      acc[formattedData.year] = {};
    }

    acc[formattedData.year][formattedData.date.getMonth() + 1] = formattedData;
    return acc;
  }, {});
};

/**
 * Formats date to `yyyy-mm-dd`
 * @param { Number } year full year
 * @param { Number } month month number, between 1 and 12
 * @param { Number } day day of the month
 * @returns { String } formatted date string
 *
 * NOTE: it might be worth moving this utility to date time utils
 * in ~/lib/utils/datetime_utility.js
 */
export const formatIso8601Date = (year, month, day) => {
  return [year, month, day]
    .map(String)
    .map((s) => s.padStart(2, '0'))
    .join('-');
};
