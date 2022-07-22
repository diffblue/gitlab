import { __ } from '~/locale';

export const HOUR_MINUTE_LIST = Array.from(Array(24).keys()).reduce((acc, num) => {
  acc[num] = num.toString().length === 1 ? `0${num}:00` : `${num}:00`;
  return acc;
}, {});

export const DAYS = {
  0: __('Sunday'),
  1: __('Monday'),
  2: __('Tuesday'),
  3: __('Wednesday'),
  4: __('Thursday'),
  5: __('Friday'),
  6: __('Saturday'),
};

export const CRONE_DEFAULT_TIME = '0 0 * * *';
export const CRONE_DEFAULT_DAY = '0 0 * * 0';

const TIME_INDEX_IN_CRONE_STRING = 2;

export const setCroneTime = ({ time, day } = { day: undefined }) => {
  let croneTime = CRONE_DEFAULT_TIME;

  if (day) {
    croneTime = croneTime.replace(/.$/, day);
  }

  return (
    croneTime.substring(0, TIME_INDEX_IN_CRONE_STRING) +
    time +
    croneTime.substring(TIME_INDEX_IN_CRONE_STRING + 1)
  );
};

export const parseCroneTime = (croneString) => {
  const isDayNumber = !Number.isNaN(Number(croneString[croneString.length - 1]));
  const isTimeNumber = !Number.isNaN(Number(croneString[TIME_INDEX_IN_CRONE_STRING]));

  return {
    day: isDayNumber ? DAYS[croneString[croneString.length - 1]] : DAYS[0],
    time: isTimeNumber
      ? HOUR_MINUTE_LIST[croneString[TIME_INDEX_IN_CRONE_STRING]]
      : HOUR_MINUTE_LIST[0],
  };
};

export const isCronDaily = (croneString) => croneString.endsWith('*');
