<script>
import { GlEmptyState } from '@gitlab/ui';
import { mapActions } from 'vuex';
import pipelineSecurityReportSummaryQuery from 'ee/security_dashboard/graphql/queries/pipeline_security_report_summary.query.graphql';
import { reportTypeToSecurityReportTypeEnum } from 'ee/vue_shared/security_reports/constants';
import { fetchPolicies } from '~/lib/graphql';
import { s__ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import VulnerabilityReport from '../shared/vulnerability_report.vue';
import ScanErrorsAlert from './scan_errors_alert.vue';
import SecurityDashboard from './security_dashboard_vuex.vue';
import SecurityReportsSummary from './security_reports_summary.vue';

export default {
  name: 'PipelineSecurityDashboard',
  components: {
    GlEmptyState,
    ScanErrorsAlert,
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
    scansWithErrors() {
      const getScans = (reportSummary) => reportSummary?.scans?.nodes || [];
      const hasErrors = (scan) => Boolean(scan.errors?.length);

      return this.reportSummary
        ? Object.values(this.reportSummary)
            // generate flat array of all scans
            .flatMap(getScans)
            .filter(hasErrors)
        : [];
    },
    hasScansWithErrors() {
      return this.scansWithErrors.length > 0;
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
};
</script>

<template>
  <div>
    <div v-if="reportSummary" class="gl-my-5">
      <scan-errors-alert v-if="hasScansWithErrors" :scans="scansWithErrors" class="gl-mb-5" />
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
