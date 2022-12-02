import { dateToYearMonthDate, formatDateAsMonth } from '~/lib/utils/datetime_utility';

export const formatYearMonthData = (ciMinutesUsage, formatMonth = false) => {
  return ciMinutesUsage.length > 0
    ? ciMinutesUsage.map((cur) => {
        const date = new Date(cur.monthIso8601);
        const formattedDate = dateToYearMonthDate(date);

        if (formatMonth) {
          return {
            ...cur,
            ...formattedDate,
            monthName: formatDateAsMonth(date, { abbreviated: false }),
          };
        }

        return {
          ...cur,
          ...formattedDate,
        };
      })
    : [];
};

export const getUsageDataByYear = (ciMinutesUsage) => {
  const formattedData = formatYearMonthData(ciMinutesUsage);

  return formattedData.reduce((prev, cur) => {
    if (prev[cur.year] != null) {
      prev[cur.year].push(cur);
    } else {
      // eslint-disable-next-line no-param-reassign
      prev[cur.year] = [cur];
    }
    return prev;
  }, {});
};

export const getSortedYears = (usageDataByYear) => {
  return Object.keys(usageDataByYear).reverse();
};
