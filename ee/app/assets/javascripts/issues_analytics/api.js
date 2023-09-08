/**
 * @typedef {Object} IssuesAnalyticsMetric
 * @property {Float} value - Float value for the metric
 */

/**
 * The key for this object is a camel-cased date (e.g., Aug_2023)
 * @typedef {Object<string, IssuesAnalyticsMetric>} IssueAnalyticsCountItem
 */

/**
 * @typedef {Object} IssueAnalyticsCountsResponseItem
 * @property {IssueAnalyticsCountItem} issuesOpened - Issues opened/created by month
 * @property {IssueAnalyticsCountItem} issuesClosed - Issues closed/completed by month
 */

/**
 * @typedef {Object} IssuesAnalyticsCountsChartItem
 * @property {String} name - Name of the series
 * @property {Array} data - Series data values in order of date range
 */

import { TOTAL_ISSUES_ANALYTICS_CHART_SERIES_NAMES } from './constants';

/**
 * Takes the issuesAnalyticsCountsQueryBuilder GraphQL response and prepares the data for
 * display in the column chart
 *
 * @param {IssueAnalyticsCountsResponseItem} data
 * @returns {IssuesAnalyticsCountsChartItem[]} Issues Analytics counts data ready for rendering in the column chart
 */
export const extractIssuesAnalyticsCounts = (data = {}) =>
  Object.entries(TOTAL_ISSUES_ANALYTICS_CHART_SERIES_NAMES).map(([queryAlias, name]) => ({
    name,
    data: data?.[queryAlias]
      ? Object.entries(data[queryAlias])
          .filter(([key]) => key !== '__typename')
          .map(([, metricData]) => metricData?.value ?? null)
      : [],
  }));
