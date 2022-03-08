<script>
import { GlEmptyState } from '@gitlab/ui';
import { mapActions } from 'vuex';
import pipelineSecurityReportSummaryQuery from 'ee/security_dashboard/graphql/queries/pipeline_security_report_summary.query.graphql';
import { reportTypeToSecurityReportTypeEnum } from 'ee/vue_shared/security_reports/constants';
import { fetchPolicies } from '~/lib/graphql';
import { s__ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import VulnerabilityReport from '../shared/vulnerability_report.vue';
import ScanAlerts, { TYPE_ERRORS, TYPE_WARNINGS } from './scan_alerts.vue';
import SecurityDashboard from './security_dashboard_vuex.vue';
import SecurityReportsSummary from './security_reports_summary.vue';

export default {
  name: 'PipelineSecurityDashboard',
  errorsAlertType: TYPE_ERRORS,
  warningsAlertType: TYPE_WARNINGS,
  components: {
    GlEmptyState,
    ScanAlerts,
    SecurityReportsSummary,
    SecurityDashboard,
    VulnerabilityReport,
  },
  mixins: [glFeatureFlagMixin()],
  inject: [
    'dashboardDocumentation',
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
        primaryButtonLink: this.dashboardDocumentation,
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
    scansWithErrors() {
      const hasErrors = (scan) => Boolean(scan.errors?.length);

      return this.scans.filter(hasErrors);
    },
    hasScansWithErrors() {
      return this.scansWithErrors.length > 0;
    },
    scansWithWarnings() {
      const hasWarnings = (scan) => Boolean(scan.warnings?.length);

      return this.scans.filter(hasWarnings);
    },
    hasScansWithWarnings() {
      return this.scansWithWarnings.length > 0;
    },
  },
  created() {
    this.setSourceBranch(this.pipeline.sourceBranch);
    this.setPipelineJobsPath(this.pipeline.jobsPath);
    this.setProjectId(this.projectId);
  },
  methods: {
    ...mapActions('vulnerabilities', ['setSourceBranch']),
    ...mapActions('pipelineJobs', ['setPipelineJobsPath', 'setProjectId']),
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
  },
};
</script>

<template>
  <div>
    <div v-if="reportSummary" class="gl-my-5">
      <scan-alerts
        v-if="hasScansWithErrors"
        :type="$options.errorsAlertType"
        :scans="scansWithErrors"
        :title="$options.i18n.parsingErrorAlertTitle"
        :description="$options.i18n.parsingErrorAlertDescription"
        class="gl-mb-5"
      />
      <scan-alerts
        v-if="hasScansWithWarnings"
        :type="$options.warningsAlertType"
        :scans="scansWithWarnings"
        :title="$options.i18n.parsingWarningAlertTitle"
        :description="$options.i18n.parsingWarningAlertDescription"
        class="gl-mb-5"
      />
      <security-reports-summary :summary="reportSummary" :jobs="jobs" />
    </div>
    <security-dashboard
      v-if="!shouldShowGraphqlVulnerabilityReport"
      :vulnerabilities-endpoint="vulnerabilitiesEndpoint"
      :lock-to-project="{ id: projectId }"
      :pipeline-id="pipeline.id"
      :loading-error-illustrations="loadingErrorIllustrations"
      :security-report-summary="reportSummary"
    >
      <template #empty-state>
        <gl-empty-state v-bind="emptyStateProps" />
      </template>
    </security-dashboard>
    <vulnerability-report v-else />
  </div>
</template>
