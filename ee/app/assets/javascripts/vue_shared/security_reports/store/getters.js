import messages from './messages';
import { statusIcon, groupedReportText } from './utils';

export {
  allReportsHaveError,
  anyReportHasError,
  anyReportHasIssues,
  areAllReportsLoading,
  areReportsLoading,
  groupedSummaryText,
  summaryCounts,
  summaryStatus,
} from '~/vue_shared/security_reports/store/getters';

export const groupedContainerScanningText = ({ containerScanning }) =>
  groupedReportText(
    containerScanning,
    messages.CONTAINER_SCANNING,
    messages.CONTAINER_SCANNING_HAS_ERROR,
    messages.CONTAINER_SCANNING_IS_LOADING,
  );

export const groupedDastText = ({ dast }) =>
  groupedReportText(dast, messages.DAST, messages.DAST_HAS_ERROR, messages.DAST_IS_LOADING);

export const groupedDependencyText = ({ dependencyScanning }) =>
  groupedReportText(
    dependencyScanning,
    messages.DEPENDENCY_SCANNING,
    messages.DEPENDENCY_SCANNING_HAS_ERROR,
    messages.DEPENDENCY_SCANNING_IS_LOADING,
  );

export const groupedCoverageFuzzingText = ({ coverageFuzzing }) =>
  groupedReportText(
    coverageFuzzing,
    messages.COVERAGE_FUZZING,
    messages.COVERAGE_FUZZING_HAS_ERROR,
    messages.COVERAGE_FUZZING_IS_LOADING,
  );

export const containerScanningStatusIcon = ({ containerScanning }) =>
  statusIcon(
    containerScanning.isLoading,
    containerScanning.hasError,
    containerScanning.newIssues.length,
  );

export const dastStatusIcon = ({ dast }) =>
  statusIcon(dast.isLoading, dast.hasError, dast.newIssues.length);

export const dependencyScanningStatusIcon = ({ dependencyScanning }) =>
  statusIcon(
    dependencyScanning.isLoading,
    dependencyScanning.hasError,
    dependencyScanning.newIssues.length,
  );

export const coverageFuzzingStatusIcon = ({ coverageFuzzing }) =>
  statusIcon(coverageFuzzing.isLoading, coverageFuzzing.hasError, coverageFuzzing.newIssues.length);

export const isBaseSecurityReportOutOfDate = (state) =>
  state.reportTypes.some((reportType) => state[reportType].baseReportOutofDate);

export const canCreateIssue = (state) =>
  Boolean(
    state.createVulnerabilityFeedbackIssuePath || state.modal?.vulnerability?.create_jira_issue_url,
  );

export const canCreateMergeRequest = (state) =>
  Boolean(state.createVulnerabilityFeedbackMergeRequestPath);

export const canDismissVulnerability = (state) =>
  Boolean(state.createVulnerabilityFeedbackDismissalPath);
