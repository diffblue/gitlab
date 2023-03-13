import { getWeekdayNames } from '~/lib/utils/datetime_utility';

export const HOUR_MINUTE_LIST = Array.from(Array(24).keys()).reduce((acc, num) => {
  acc[num] = num.toString().length === 1 ? `0${num}:00` : `${num}:00`;
  return acc;
}, {});

export const DAYS = getWeekdayNames().reduce((acc, curr, i) => {
  acc[i] = curr;
  return acc;
}, {});

export const CRON_DEFAULT_TIME = '0 0 * * *';
export const CRON_DEFAULT_DAY = '0 0 * * 0';

const TIME_INDEX_IN_CRON_STRING = 2;

/**
 * Creates cron syntax given a time and day (no other options are currently supported for rule mode)
 * @param {Number} time that the scanner should run (24hr time, 0 through 24)
 * @param {Number} day that the scanner should run (0 through 6)
 * @returns {String} resulting cron syntax
 */

export const setCronTime = ({ time, day } = { day: undefined }) => {
  let cronTime = CRON_DEFAULT_TIME;

  if (day) {
    cronTime = cronTime.replace(/.$/, day);
  }

  return (
    cronTime.substring(0, TIME_INDEX_IN_CRON_STRING) +
    time +
    cronTime.substring(TIME_INDEX_IN_CRON_STRING + 1)
  );
};

/**
 * Finds the first number in a specified cron syntax position
 * @param {String} cronString scheduling syntax
 * @param {Number} startIndex index  (e.g. 1 through 5), defaults to the second index by default because only hours are supported by rule mode at the moment
 * @returns {String}
 */
export const findFirstNumberInCronString = (cronString, startIndex = TIME_INDEX_IN_CRON_STRING) => {
  let index = startIndex;
  let result = '';

  const isNumber = /\d+/;

  while (isNumber.test(cronString[index])) {
    result += cronString[index];
    index += 1;
  }

  return result;
};

/**
 * Retrieves the day and time from cron syntax (no other options are currently supported for rule mode)
 * @param {String} cronString syntax
 * @returns {Object} object containing resulting day and time of schedule
 */
export const parseCronTime = (cronString) => {
  const numberInTimePlaceholder = findFirstNumberInCronString(cronString);
  const isDayNumber = !Number.isNaN(Number(cronString[cronString.length - 1]));
  const isTimeNumber = !Number.isNaN(Number(numberInTimePlaceholder));

  return {
    dayIndex: isDayNumber ? cronString[cronString.length - 1] : 0,
    day: isDayNumber ? DAYS[cronString[cronString.length - 1]] || DAYS[0] : DAYS[0],
    timeIndex: isTimeNumber ? numberInTimePlaceholder || 0 : 0,
    time: isTimeNumber
      ? HOUR_MINUTE_LIST[numberInTimePlaceholder] || HOUR_MINUTE_LIST[0]
      : HOUR_MINUTE_LIST[0],
  };
};

export const isCronDaily = (cronString) => cronString.endsWith('*');
