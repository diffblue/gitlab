import { __, sprintf } from '~/locale';
import { getDateInPast } from '~/lib/utils/datetime_utility';

export const MAX_DATE_RANGE = 31;

export const TODAY = new Date();

/**
 * The default options to display in the date_range_filter.
 *
 * Each options consists of:
 *
 * text - Text to display in the dropdown item
 * startDate - Optional, the start date to set
 * endDate - Optional, the end date to set
 * showDateRangePicker - Optional, show the date range picker component and uses
 *                       it to set the date.
 */
export const DATE_RANGE_OPTIONS = [
  {
    text: sprintf(__('Last %{days} days'), { days: 30 }),
    startDate: getDateInPast(TODAY, 30),
    endDate: TODAY,
  },
  {
    text: sprintf(__('Last %{days} days'), { days: 7 }),
    startDate: getDateInPast(TODAY, 7),
    endDate: TODAY,
  },
  {
    text: __('Today'),
    startDate: TODAY,
    endDate: TODAY,
  },
  {
    text: __('Custom range'),
    showDateRangePicker: true,
  },
];

export const DATE_RANGE_FILTER_I18N = {
  tooltip: sprintf(__('Date range limited to %{number} days'), {
    number: MAX_DATE_RANGE,
  }),
  to: __('To'),
  from: __('From'),
};

export const DEFAULT_SELECTED_OPTION_INDEX = 1;
