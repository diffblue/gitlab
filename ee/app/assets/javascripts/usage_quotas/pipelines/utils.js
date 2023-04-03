import { dateToYearMonthDate, newDateAsLocaleTime } from '~/lib/utils/datetime_utility';

export const formatYearMonthData = (ciMinutesUsage, formatMonth = false) => {
  return ciMinutesUsage.length > 0
    ? ciMinutesUsage.map((cur) => {
        const date = newDateAsLocaleTime(cur.monthIso8601);
        const formattedDate = dateToYearMonthDate(date);

        if (formatMonth) {
          return {
            ...formattedDate,
            ...cur,
          };
        }

        return {
          ...formattedDate,
          ...cur,
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

export const getUsageDataByYearObject = (ciMinutesUsage) => {
  const formattedData = formatYearMonthData(ciMinutesUsage, true);

  return formattedData.length > 0
    ? formattedData.reduce((prev, cur) => {
        if (!prev[cur.year]) {
          // eslint-disable-next-line no-param-reassign
          prev[cur.year] = {};
        }

        // eslint-disable-next-line no-param-reassign
        prev[cur.year][cur.month] = cur;
        return prev;
      }, {})
    : {};
};

export const getSortedYears = (usageDataByYear) => {
  return Object.keys(usageDataByYear).reverse();
};
