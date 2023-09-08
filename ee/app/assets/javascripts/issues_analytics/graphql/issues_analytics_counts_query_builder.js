import { gql } from '@apollo/client/core';
import { dateFormats } from '~/analytics/shared/constants';
import dateFormat from '~/lib/dateformat';
import { getMonthNames } from '~/lib/utils/datetime_utility';
import { ISSUES_OPENED_COUNT_ALIAS, ISSUES_COMPLETED_COUNT_ALIAS } from '../constants';

/**
 * A GraphQL query building function which accepts a
 * startDate and endDate, returning a parsed query string
 * which nests sub-queries for the number of issues opened and closed
 * grouped by month at the group or project level.
 *
 * @param {Date} startDate - the startDate for the data range
 * @param {Date} endDate - the endDate for the data range
 * @param {Boolean} isProject
 *
 * @return {String} the parsed GraphQL query string
 */
export default (startDate = null, endDate = null, isProject = false) => {
  const issuesOpenedCountsByMonth = [];
  const issuesClosedCountsByMonth = [];
  const abbrMonthNames = getMonthNames(true);

  for (
    let dateCursor = new Date(endDate);
    dateCursor >= startDate;
    dateCursor.setMonth(dateCursor.getMonth(), 0)
  ) {
    const monthIndex = dateCursor.getMonth();
    const month = abbrMonthNames[monthIndex];
    const year = dateCursor.getFullYear();
    const fromDate = new Date(year, monthIndex, 1);
    const toDate = new Date(year, monthIndex + 1, 1);
    const metricCountQuery = (metricCountType) => `
      ${month}_${year}: ${metricCountType}(
        from: "${dateFormat(fromDate, dateFormats.isoDate, true)}",
        to: "${dateFormat(toDate, dateFormats.isoDate, true)}"
        assigneeUsernames: $assigneeUsernames
        authorUsername: $authorUsername
        milestoneTitle: $milestoneTitle
        labelNames: $labelNames
        ) { value }
    `;

    issuesOpenedCountsByMonth.unshift(metricCountQuery('issueCount'));
    issuesClosedCountsByMonth.unshift(metricCountQuery('issuesCompletedCount'));
  }

  if (!issuesOpenedCountsByMonth.length || !issuesClosedCountsByMonth.length) return '';

  return gql`
    query($fullPath: ID!, $assigneeUsernames: [String!], $authorUsername: String, $milestoneTitle: String, $labelNames: [String!]) {
      issuesAnalyticsCountsData: ${isProject ? 'project' : 'group'}(fullPath: $fullPath) {
        id
        ${ISSUES_OPENED_COUNT_ALIAS}: flowMetrics {
            ${issuesOpenedCountsByMonth}
        }
        ${ISSUES_COMPLETED_COUNT_ALIAS}: flowMetrics {
            ${issuesClosedCountsByMonth}
        }
      }
    }
  `;
};
