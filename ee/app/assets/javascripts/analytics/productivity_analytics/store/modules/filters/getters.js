import { dateFormats } from '~/analytics/shared/constants';
import dateFormat from '~/lib/dateformat';
import { getDateInPast, beginOfDayTime, endOfDayTime } from '~/lib/utils/datetime_utility';
import { chartKeys, scatterPlotAddonQueryDays } from '../../../constants';

/**
 * Returns an object of common filter parameters based on the filter's state
 * which will be used for querying the API to retrieve chart and MR table data.
 * The returned object hast the following form:
 *
 * {
 *   group_id: 'gitlab-org',
 *   project_id: 'gitlab-org/gitlab-test',
 *   author_username: 'author',
 *   milestone_title: 'my milestone',
 *   label_name: ['my label', 'yet another label'],
 *   merged_after: '2019-06-11T00:00:00Z'
 *   merged_before: '2019-09-09T23:59:59Z'
 * }
 *
 */
export const getCommonFilterParams = (state, getters) => (chartKey) => {
  const {
    groupNamespace,
    projectPath,
    startDate,
    endDate,
    authorUsername,
    labelName,
    milestoneTitle,
    notAuthorUsername,
    notMilestoneTitle,
    notLabelName,
  } = state;

  // for the scatterplot we need to query the API with a date prior to the selected start date
  const mergedAfterDate =
    chartKey && chartKey === chartKeys.scatterplot
      ? dateFormat(getters.scatterplotStartDate, dateFormats.isoDate)
      : dateFormat(startDate, dateFormats.isoDate);

  return {
    group_id: groupNamespace,
    project_id: projectPath,
    author_username: authorUsername,
    milestone_title: milestoneTitle,
    label_name: labelName,
    'not[author_username]': notAuthorUsername,
    'not[milestone_title]': notMilestoneTitle,
    'not[label_name]': notLabelName,
    merged_after: `${mergedAfterDate}${beginOfDayTime}`,
    merged_before: `${dateFormat(endDate, dateFormats.isoDate)}${endOfDayTime}`,
  };
};

/**
 * Returns the start date for the scatterplot.
 * It computes a dateInPast based on the selected startDate
 * and a default number of offset days (offsetDays)
 *
 * When a minDate exists and the minDate is after the computed dateInPast,
 * the minDate is returned. Otherwise the computed dateInPast is returned.
 */
export const scatterplotStartDate = (state) => {
  const { startDate, minDate } = state;
  const dateInPast = getDateInPast(startDate, scatterPlotAddonQueryDays);

  return minDate && minDate > dateInPast ? minDate : dateInPast;
};
