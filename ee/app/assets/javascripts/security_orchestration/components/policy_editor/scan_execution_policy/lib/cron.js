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

export const setCronTime = ({ time, day } = { day: undefined }) => {
  let croneTime = CRON_DEFAULT_TIME;

  if (day) {
    croneTime = croneTime.replace(/.$/, day);
  }

  return (
    croneTime.substring(0, TIME_INDEX_IN_CRON_STRING) +
    time +
    croneTime.substring(TIME_INDEX_IN_CRON_STRING + 1)
  );
};

export const parseCronTime = (cronString) => {
  const isDayNumber = !Number.isNaN(Number(cronString[cronString.length - 1]));
  const isTimeNumber = !Number.isNaN(Number(cronString[TIME_INDEX_IN_CRON_STRING]));

  return {
    day: isDayNumber ? DAYS[cronString[cronString.length - 1]] : DAYS[0],
    time: isTimeNumber
      ? HOUR_MINUTE_LIST[cronString[TIME_INDEX_IN_CRON_STRING]]
      : HOUR_MINUTE_LIST[0],
  };
};

export const isCronDaily = (cronString) => cronString.endsWith('*');
