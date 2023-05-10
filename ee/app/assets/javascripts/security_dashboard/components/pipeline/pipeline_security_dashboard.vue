<script>
import { GlEmptyState, GlButton } from '@gitlab/ui';
import pipelineSecurityReportSummaryQuery from 'ee/security_dashboard/graphql/queries/pipeline_security_report_summary.query.graphql';
import { reportTypeToSecurityReportTypeEnum } from 'ee/vue_shared/security_reports/constants';
import { fetchPolicies } from '~/lib/graphql';
import { s__ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { helpPagePath } from '~/helpers/help_page_helper';
import { DOC_PATH_SECURITY_CONFIGURATION } from 'ee/security_dashboard/constants';
import ScanAlerts, { TYPE_ERRORS, TYPE_WARNINGS } from './scan_alerts.vue';
import ReportStatusAlert, { STATUS_PURGED } from './report_status_alert.vue';
import SecurityReportsSummary from './security_reports_summary.vue';
import SecurityDashboard from './security_dashboard_vuex.vue';

export default {
  name: 'PipelineSecurityDashboard',
  errorsAlertType: TYPE_ERRORS,
  warningsAlertType: TYPE_WARNINGS,
  scanPurgedStatus: STATUS_PURGED,
  components: {
    GlEmptyState,
    ReportStatusAlert,
    ScanAlerts,
    SecurityReportsSummary,
    SecurityDashboard,
    PipelineVulnerabilityReport: () => import('./pipeline_vulnerability_report.vue'),
    GlButton,
  },
  mixins: [glFeatureFlagMixin()],
  inject: [
    'emptyStateSvgPath',
    'loadingErrorIllustrations',
    'pipeline',
    'projectFullPath',
    'projectId',
    'vulnerabilitiesEndpoint',
  ],
  data() {
    return {
      securityReportSummary: {},
    };
  },
  apollo: {
    securityReportSummary: {
      query: pipelineSecurityReportSummaryQuery,
      fetchPolicy: fetchPolicies.NETWORK_ONLY,
      variables() {
        return {
          fullPath: this.projectFullPath,
          pipelineIid: this.pipeline.iid,
          reportTypes: Object.values(reportTypeToSecurityReportTypeEnum),
        };
      },
      update(data) {
        const summary = {
          reports: data?.project?.pipeline?.securityReportSummary,
          jobs: data?.project?.pipeline?.jobs?.nodes,
        };
        return summary?.reports && Object.keys(summary.reports).length ? summary : null;
      },
    },
  },
  computed: {
    reportSummary() {
      return this.securityReportSummary?.reports;
    },
    jobs() {
      return this.securityReportSummary?.jobs;
    },
    shouldShowGraphqlVulnerabilityReport() {
      return this.glFeatures.pipelineSecurityDashboardGraphql;
    },
    emptyStateProps() {
      return {
        svgPath: this.emptyStateSvgPath,
        title: s__('SecurityReports|No vulnerabilities found for this pipeline'),
        description: s__(
          `SecurityReports|While it's rare to have no vulnerabilities for your pipeline, it can happen. In any event, we ask that you double check your settings to make sure all security scanning jobs have passed successfully.`,
        ),
        primaryButtonLink: DOC_PATH_SECURITY_CONFIGURATION,
        primaryButtonText: s__('SecurityReports|Learn more about setting up your dashboard'),
      };
    },
    scans() {
      const getScans = (reportSummary) => reportSummary?.scans?.nodes || [];

      return this.reportSummary
        ? Object.values(this.reportSummary)
            // generate flat array of all scans
            .flatMap(getScans)
        : [];
    },
    hasScans() {
      return this.scans.length > 0;
    },
    purgedScans() {
      return this.scans.filter((scan) => scan.status === this.$options.scanPurgedStatus);
    },
    hasPurgedScans() {
      return this.purgedScans.length > 0;
    },
    scansWithErrors() {
      const hasErrors = (scan) => Boolean(scan.errors?.length);

      return this.scans.filter(hasErrors);
    },
    showScanErrors() {
      return this.scansWithErrors.length > 0 && !this.hasPurgedScans;
    },
    scansWithWarnings() {
      const hasWarnings = (scan) => Boolean(scan.warnings?.length);

      return this.scans.filter(hasWarnings);
    },
    showScanWarnings() {
      return this.scansWithWarnings.length > 0 && !this.hasPurgedScans;
    },
  },
  i18n: {
    parsingErrorAlertTitle: s__('SecurityReports|Error parsing security reports'),
    parsingErrorAlertDescription: s__(
      'SecurityReports|The following security reports contain one or more vulnerability findings that could not be parsed and were not recorded. To investigate a report, download the artifacts in the job output. Ensure the security report conforms to the relevant %{helpPageLinkStart}JSON schema%{helpPageLinkEnd}.',
    ),
    parsingWarningAlertTitle: s__('SecurityReports|Warning parsing security reports'),
    parsingWarningAlertDescription: s__(
      'SecurityReports|Check the messages generated while parsing the following security reports, as they may prevent the results from being ingested by GitLab. Ensure the security report conforms to a supported %{helpPageLinkStart}JSON schema%{helpPageLinkEnd}.',
    ),
    pageDescription: s__(
      `SecurityReports|Results show vulnerabilities introduced by the merge request, in addition to existing vulnerabilities from the latest successful pipeline in your project's default branch.`,
    ),
    pageDescriptionHelpLink: helpPagePath(
      'user/application_security/vulnerability_report/pipeline.html',
    ),
  },
};
</script>

<template>
  <div class="gl-mt-5">
    <p>
      {{ $options.i18n.pageDescription }}
      <gl-button
        class="gl-ml-2 vertical-align-text-top"
        icon="question-o"
        variant="link"
        target="_blank"
        :href="$options.i18n.pageDescriptionHelpLink"
      />
    </p>

    <div v-if="hasScans" class="gl-mb-5">
      <scan-alerts
        v-if="showScanErrors"
        :type="$options.errorsAlertType"
        :scans="scansWithErrors"
        :title="$options.i18n.parsingErrorAlertTitle"
        :description="$options.i18n.parsingErrorAlertDescription"
        class="gl-mb-5"
      />
      <scan-alerts
        v-if="showScanWarnings"
        :type="$options.warningsAlertType"
        :scans="scansWithWarnings"
        :title="$options.i18n.parsingWarningAlertTitle"
        :description="$options.i18n.parsingWarningAlertDescription"
        class="gl-mb-5"
      />

      <report-status-alert v-if="hasPurgedScans" class="gl-mb-5" />
      <security-reports-summary :summary="reportSummary" :jobs="jobs" />
    </div>

    <security-dashboard
      v-if="!shouldShowGraphqlVulnerabilityReport"
      :vulnerabilities-endpoint="vulnerabilitiesEndpoint"
      :lock-to-project="/* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ {
        id: projectId,
      } /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */"
      :pipeline-id="pipeline.id"
      :loading-error-illustrations="loadingErrorIllustrations"
      :security-report-summary="reportSummary"
    >
      <template #empty-state>
        <gl-empty-state v-bind="emptyStateProps" />
      </template>
    </security-dashboard>
    <pipeline-vulnerability-report v-else data-testid="pipeline-vulnerability-report" />
  </div>
</template>
