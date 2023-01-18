import { helpPagePath } from '~/helpers/help_page_helper';
import dateFormat from '~/lib/dateformat';
import { nDaysBefore, nMonthsBefore, getStartOfDay, dayAfter } from '~/lib/utils/datetime_utility';
import { __, sprintf } from '~/locale';

export const environmentTierDocumentationHref = helpPagePath('ci/environments/index.html', {
  anchor: 'deployment-tier-of-environments',
});

/* eslint-disable @gitlab/require-i18n-strings */
export const LAST_WEEK = 'LAST_WEEK';
export const LAST_MONTH = 'LAST_MONTH';
export const LAST_90_DAYS = 'LAST_90_DAYS';
export const LAST_180_DAYS = 'LAST_180_DAYS';
/* eslint-enable @gitlab/require-i18n-strings */

// Compute all relative dates based on the _beginning_ of today.
// We use this date as the end date for the charts. This causes
// the current date to be the last day included in the graph.
const startOfToday = getStartOfDay(new Date(), { utc: true });

// We use this date as the "to" parameter for the API. This allows
// us to get DORA 4 metrics about the current day.
const startOfTomorrow = dayAfter(startOfToday, { utc: true });

const lastWeek = nDaysBefore(startOfTomorrow, 7, { utc: true });
const lastMonth = nMonthsBefore(startOfTomorrow, 1, { utc: true });
const last90Days = nDaysBefore(startOfTomorrow, 90, { utc: true });
const last180Days = nDaysBefore(startOfTomorrow, 180, { utc: true });
const apiDateFormatString = 'isoDateTime';
const titleDateFormatString = 'mmm d';
const sharedRequestParams = {
  interval: 'daily',
  end_date: dateFormat(startOfTomorrow, apiDateFormatString, true),

  // We will never have more than 91 records (1 record per day), so we
  // don't have to worry about making multiple requests to get all the results
  per_page: 100,
};

export const averageSeriesOptions = {
  areaStyle: {
    opacity: 0,
  },
};

const formatDateRangeString = (startDate) => {
  const start = dateFormat(startDate, titleDateFormatString, true);
  const end = dateFormat(startOfToday, titleDateFormatString, true);
  return `${start} - ${end}`;
};

const lastXDays = __('Last %{days} days');

export const allChartDefinitions = [
  {
    id: LAST_WEEK,
    title: __('Last week'),
    range: formatDateRangeString(lastWeek),
    startDate: lastWeek,
    endDate: startOfTomorrow,
    requestParams: {
      ...sharedRequestParams,
      start_date: dateFormat(lastWeek, apiDateFormatString, true),
    },
  },
  {
    id: LAST_MONTH,
    title: __('Last month'),
    range: formatDateRangeString(lastMonth),
    startDate: lastMonth,
    endDate: startOfTomorrow,
    requestParams: {
      ...sharedRequestParams,
      start_date: dateFormat(lastMonth, apiDateFormatString, true),
    },
  },
  {
    id: LAST_90_DAYS,
    title: sprintf(lastXDays, { days: 90 }),
    range: formatDateRangeString(last90Days),
    startDate: last90Days,
    endDate: startOfTomorrow,
    requestParams: {
      ...sharedRequestParams,
      start_date: dateFormat(last90Days, apiDateFormatString, true),
    },
  },
  {
    id: LAST_180_DAYS,
    title: sprintf(lastXDays, { days: 180 }),
    range: formatDateRangeString(last180Days),
    startDate: last180Days,
    endDate: startOfTomorrow,
    requestParams: {
      ...sharedRequestParams,
      start_date: dateFormat(last180Days, apiDateFormatString, true),
    },
  },
];
