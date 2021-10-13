import {
  CRITICAL,
  HIGH,
  MEDIUM,
  LOW,
} from 'ee/security_dashboard/store/modules/vulnerabilities/constants';
import {
  groupedContainerScanningText,
  groupedDastText,
  groupedDependencyText,
  groupedCoverageFuzzingText,
  groupedSummaryText,
  allReportsHaveError,
  areReportsLoading,
  areAllReportsLoading,
  containerScanningStatusIcon,
  dastStatusIcon,
  dependencyScanningStatusIcon,
  anyReportHasError,
  anyReportHasIssues,
  summaryCounts,
  isBaseSecurityReportOutOfDate,
  canCreateIssue,
  canCreateMergeRequest,
  canDismissVulnerability,
} from 'ee/vue_shared/security_reports/store/getters';
import createApiFuzzingState from 'ee/vue_shared/security_reports/store/modules/api_fuzzing/state';
import createSastState from 'ee/vue_shared/security_reports/store/modules/sast/state';
import createSecretDetectionState from 'ee/vue_shared/security_reports/store/modules/secret_detection/state';
import createState from 'ee/vue_shared/security_reports/store/state';
import { groupedTextBuilder } from 'ee/vue_shared/security_reports/store/utils';

const MOCK_PATH = 'fake/path.json';

const generateVuln = (severity) => ({ severity });

describe('Security reports getters', () => {
  let state = {};

  beforeEach(() => {
    state = createState();
    state.sast = createSastState();
    state.secretDetection = createSecretDetectionState();
    state.apiFuzzing = createApiFuzzingState();
  });

  describe.each`
    name                     | scanner                 | getter
    ${'Dependency scanning'} | ${'dependencyScanning'} | ${groupedDependencyText}
    ${'Container scanning'}  | ${'containerScanning'}  | ${groupedContainerScanningText}
    ${'DAST'}                | ${'dast'}               | ${groupedDastText}
    ${'Coverage fuzzing'}    | ${'coverageFuzzing'}    | ${groupedCoverageFuzzingText}
  `('grouped text for $name', ({ name, scanner, getter }) => {
    it.each`
      vulnerabilities                                     | message
      ${[]}                                               | ${groupedTextBuilder({ reportType: name, critical: 0, high: 0, other: 0 })}
      ${[generateVuln(CRITICAL), generateVuln(CRITICAL)]} | ${groupedTextBuilder({ reportType: name, critical: 2, high: 0, other: 0 })}
      ${[generateVuln(HIGH), generateVuln(HIGH)]}         | ${groupedTextBuilder({ reportType: name, critical: 0, high: 2, other: 0 })}
      ${[generateVuln(LOW), generateVuln(MEDIUM)]}        | ${groupedTextBuilder({ reportType: name, critical: 0, high: 0, other: 2 })}
      ${[generateVuln(CRITICAL), generateVuln(HIGH)]}     | ${groupedTextBuilder({ reportType: name, critical: 1, high: 1, other: 0 })}
      ${[generateVuln(CRITICAL), generateVuln(LOW)]}      | ${groupedTextBuilder({ reportType: name, critical: 1, high: 0, other: 1 })}
    `('should build the message as "$message"', ({ vulnerabilities, message }) => {
      state[scanner].newIssues = vulnerabilities;
      expect(getter(state)).toEqual(message);
    });
  });

  describe('summaryCounts', () => {
    it('returns 0 count for empty state', () => {
      expect(summaryCounts(state)).toEqual({
        critical: 0,
        high: 0,
        other: 0,
      });
    });

    describe('combines all reports', () => {
      it('of the same severity', () => {
        state.containerScanning.newIssues = [generateVuln(CRITICAL)];
        state.dast.newIssues = [generateVuln(CRITICAL)];
        state.dependencyScanning.newIssues = [generateVuln(CRITICAL)];
        state.coverageFuzzing.newIssues = [generateVuln(CRITICAL)];

        expect(summaryCounts(state)).toEqual({
          critical: 4,
          high: 0,
          other: 0,
        });
      });

      it('of different severities', () => {
        state.containerScanning.newIssues = [generateVuln(CRITICAL)];
        state.dast.newIssues = [generateVuln(CRITICAL), generateVuln(HIGH)];
        state.dependencyScanning.newIssues = [generateVuln(LOW)];
        state.coverageFuzzing.newIssues = [generateVuln(HIGH)];

        expect(summaryCounts(state)).toEqual({
          critical: 2,
          high: 2,
          other: 1,
        });
      });
    });
  });

  describe('groupedSummaryText', () => {
    it('returns failed text', () => {
      expect(
        groupedSummaryText(state, {
          allReportsHaveError: true,
          areReportsLoading: false,
          summaryCounts: {},
        }),
      ).toEqual({ message: 'Security scanning failed loading any results' });
    });

    it('returns is loading text', () => {
      expect(
        groupedSummaryText(state, {
          allReportsHaveError: false,
          areReportsLoading: true,
          summaryCounts: {},
        }),
      ).toEqual(
        groupedTextBuilder({
          reportType: 'Security scanning',
          critical: 0,
          high: 0,
          other: 0,
          status: 'is loading',
        }),
      );
    });

    it('returns no new text if there are existing ones', () => {
      expect(
        groupedSummaryText(state, {
          allReportsHaveError: false,
          areReportsLoading: false,
          summaryCounts: {},
        }),
      ).toEqual(
        groupedTextBuilder({
          reportType: 'Security scanning',
          critical: 0,
          high: 0,
          other: 0,
          status: '',
        }),
      );
    });
  });

  describe('dastStatusIcon', () => {
    it('returns warning with new issues', () => {
      state.dast.newIssues = [{}];

      expect(dastStatusIcon(state)).toEqual('warning');
    });

    it('returns warning with failed report', () => {
      state.dast.hasError = true;

      expect(dastStatusIcon(state)).toEqual('warning');
    });

    it('returns success with no new issues or failed report', () => {
      expect(dastStatusIcon(state)).toEqual('success');
    });
  });

  describe('containerScanningStatusIcon', () => {
    it('returns warning with new issues', () => {
      state.containerScanning.newIssues = [{}];

      expect(containerScanningStatusIcon(state)).toEqual('warning');
    });

    it('returns warning with failed report', () => {
      state.containerScanning.hasError = true;

      expect(containerScanningStatusIcon(state)).toEqual('warning');
    });

    it('returns success with no new issues or failed report', () => {
      expect(containerScanningStatusIcon(state)).toEqual('success');
    });
  });

  describe('dependencyScanningStatusIcon', () => {
    it('returns warning with new issues', () => {
      state.dependencyScanning.newIssues = [{}];

      expect(dependencyScanningStatusIcon(state)).toEqual('warning');
    });

    it('returns warning with failed report', () => {
      state.dependencyScanning.hasError = true;

      expect(dependencyScanningStatusIcon(state)).toEqual('warning');
    });

    it('returns success with no new issues or failed report', () => {
      expect(dependencyScanningStatusIcon(state)).toEqual('success');
    });
  });

  describe('areReportsLoading', () => {
    it('returns true when any report is loading', () => {
      state.dast.isLoading = true;

      expect(areReportsLoading(state)).toEqual(true);
    });

    it('returns false when none of the reports are loading', () => {
      expect(areReportsLoading(state)).toEqual(false);
    });
  });

  describe('areAllReportsLoading', () => {
    it('returns true when all reports are loading', () => {
      state.sast.isLoading = true;
      state.dast.isLoading = true;
      state.containerScanning.isLoading = true;
      state.dependencyScanning.isLoading = true;
      state.secretDetection.isLoading = true;
      state.coverageFuzzing.isLoading = true;
      state.apiFuzzing.isLoading = true;

      expect(areAllReportsLoading(state)).toEqual(true);
    });

    it('returns false when some of the reports are loading', () => {
      state.sast.isLoading = true;

      expect(areAllReportsLoading(state)).toEqual(false);
    });

    it('returns false when none of the reports are loading', () => {
      expect(areAllReportsLoading(state)).toEqual(false);
    });
  });

  describe('allReportsHaveError', () => {
    it('returns true when all reports have error', () => {
      state.sast.hasError = true;
      state.dast.hasError = true;
      state.containerScanning.hasError = true;
      state.dependencyScanning.hasError = true;
      state.secretDetection.hasError = true;
      state.coverageFuzzing.hasError = true;
      state.apiFuzzing.hasError = true;

      expect(allReportsHaveError(state)).toEqual(true);
    });

    it('returns false when none of the reports have error', () => {
      expect(allReportsHaveError(state)).toEqual(false);
    });

    it('returns false when one of the reports does not have error', () => {
      state.dast.hasError = false;
      state.containerScanning.hasError = true;
      state.dependencyScanning.hasError = true;
      state.secretDetection.hasError = true;

      expect(allReportsHaveError(state)).toEqual(false);
    });
  });

  describe('anyReportHasError', () => {
    it('returns true when any of the reports has error', () => {
      state.dast.hasError = true;

      expect(anyReportHasError(state)).toEqual(true);
    });

    it('returns false when none of the reports has error', () => {
      expect(anyReportHasError(state)).toEqual(false);
    });
  });

  describe('anyReportHasIssues', () => {
    it('returns true when any of the reports has new issues', () => {
      state.dast.newIssues.push(generateVuln(LOW));

      expect(anyReportHasIssues(state)).toEqual(true);
    });

    it('returns false when none of the reports has error', () => {
      expect(anyReportHasIssues(state)).toEqual(false);
    });
  });

  describe('isBaseSecurityReportOutOfDate', () => {
    it('returns false when none reports are out of date', () => {
      expect(isBaseSecurityReportOutOfDate(state)).toEqual(false);
    });

    it('returns true when any of the reports is out of date', () => {
      state.dast.baseReportOutofDate = true;
      expect(isBaseSecurityReportOutOfDate(state)).toEqual(true);
    });
  });

  describe('canCreateIssue', () => {
    it.each`
      createVulnerabilityFeedbackIssuePath | createJiraIssueUrl  | expectedReturnValue
      ${''}                                | ${''}               | ${false}
      ${'/foo/bar'}                        | ${''}               | ${true}
      ${''}                                | ${'http://foo.bar'} | ${true}
      ${'/foo/bar'}                        | ${'http://foo.bar'} | ${true}
    `(
      'returns "$expectedReturnValue" with createVulnerabilityFeedbackIssuePath set to "createVulnerabilityFeedbackIssuePath" and modal.vulnerability.create_jira_issue_url to "$createJiraIssueUrl"',
      ({ createVulnerabilityFeedbackIssuePath, createJiraIssueUrl, expectedReturnValue }) => {
        state.createVulnerabilityFeedbackIssuePath = createVulnerabilityFeedbackIssuePath;
        state.modal = {
          vulnerability: {
            create_jira_issue_url: createJiraIssueUrl,
          },
        };

        expect(canCreateIssue(state)).toEqual(expectedReturnValue);
      },
    );
  });

  describe('canCreateMergeRequest', () => {
    it('returns false if no feedback path is defined', () => {
      expect(canCreateMergeRequest(state)).toEqual(false);
    });

    it('returns true if a feedback path is defined', () => {
      state.createVulnerabilityFeedbackMergeRequestPath = MOCK_PATH;

      expect(canCreateMergeRequest(state)).toEqual(true);
    });
  });

  describe('canDismissVulnerability', () => {
    it('returns false if no feedback path is defined', () => {
      expect(canDismissVulnerability(state)).toEqual(false);
    });

    it('returns true if a feedback path is defined', () => {
      state.createVulnerabilityFeedbackDismissalPath = MOCK_PATH;

      expect(canDismissVulnerability(state)).toEqual(true);
    });
  });
});
