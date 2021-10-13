import dateFormat from 'dateformat';
import { dateFormats } from '~/analytics/shared/constants';
import { getDateInPast, nMonthsBefore } from '~/lib/utils/datetime_utility';
import { s__ } from '~/locale';

export const CHART_HEIGHT = 350;
export const INNER_CHART_HEIGHT = 200;
export const CHART_X_AXIS_ROTATE = 45;
export const CHART_X_AXIS_NAME_TOP_PADDING = 55;

export const DATE_OPTIONS = [
  {
    text: s__('ContributionAnalytics|Last week'),
    value: dateFormat(getDateInPast(new Date(), 7), dateFormats.isoDate),
  },
  {
    text: s__('ContributionAnalytics|Last month'),
    value: dateFormat(nMonthsBefore(new Date(), 1), dateFormats.isoDate),
  },
  {
    text: s__('ContributionAnalytics|Last 3 months'),
    value: dateFormat(nMonthsBefore(new Date(), 3), dateFormats.isoDate),
  },
];
