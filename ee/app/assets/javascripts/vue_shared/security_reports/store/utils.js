import {
  groupedTextBuilder,
  countVulnerabilities,
} from '~/vue_shared/security_reports/store/utils';

export { groupedTextBuilder, countVulnerabilities };

/**
 * Returns the index of an issue in given list
 * @param {Array} issues
 * @param {Object} issue
 */
export const findIssueIndex = (issues, issue) => issues.findIndex((el) => el.uuid === issue.uuid);

export const statusIcon = (loading = false, failed = false, newIssues = 0, neutralIssues = 0) => {
  if (loading) {
    return 'loading';
  }

  if (failed || newIssues > 0 || neutralIssues > 0) {
    return 'warning';
  }

  return 'success';
};

/**
 * Generates a report message based on some of the report parameters and supplied messages.
 *
 * @param {Object} report The report to generate the text for
 * @param {String} reportType The report type. e.g. SAST
 * @param {String} errorMessage The message to show if there's an error in the report
 * @param {String} loadingMessage The message to show if the report is still loading
 * @returns {String}
 */
export const groupedReportText = (report, reportType, errorMessage, loadingMessage) => {
  if (report.hasError) {
    return { message: errorMessage };
  }

  if (report.isLoading) {
    return { message: loadingMessage };
  }

  return groupedTextBuilder({
    reportType,
    ...countVulnerabilities(report.newIssues),
  });
};
