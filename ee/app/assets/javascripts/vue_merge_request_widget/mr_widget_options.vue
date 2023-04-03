<script>
import { GlSprintf, GlLink } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import reportsMixin from 'ee/vue_shared/security_reports/mixins/reports_mixin';
import { registerExtension } from '~/vue_merge_request_widget/components/extensions';
import { s__, __, sprintf } from '~/locale';
import CEWidgetOptions from '~/vue_merge_request_widget/mr_widget_options.vue';
import MrWidgetJiraAssociationMissing from './components/states/mr_widget_jira_association_missing.vue';
import MrWidgetPolicyViolation from './components/states/mr_widget_policy_violation.vue';
import MrWidgetGeoSecondaryNode from './components/states/mr_widget_secondary_geo_node.vue';
import WidgetContainer from './components/widget/app.vue';
import loadPerformanceExtension from './extensions/load_performance';
import browserPerformanceExtension from './extensions/browser_performance';
import statusChecksExtension from './extensions/status_checks';
import metricsExtension from './extensions/metrics';
import licenseComplianceExtension from './extensions/license_compliance';

export default {
  components: {
    GlSprintf,
    GlLink,
    WidgetContainer,
    MrWidgetGeoSecondaryNode,
    MrWidgetPolicyViolation,
    MrWidgetJiraAssociationMissing,
    BlockingMergeRequestsReport: () =>
      import('./components/blocking_merge_requests/blocking_merge_requests_report.vue'),
    GroupedSecurityReportsApp: () =>
      import('ee/vue_shared/security_reports/grouped_security_reports_app.vue'),
    GroupedMetricsReportsApp: () =>
      import('ee/vue_shared/metrics_reports/grouped_metrics_reports_app.vue'),
  },
  directives: {
    SafeHtml,
  },
  extends: CEWidgetOptions,
  mixins: [reportsMixin],
  data() {
    return {
      isLoadingBrowserPerformance: false,
      isLoadingLoadPerformance: false,
      loadingBrowserPerformanceFailed: false,
      loadingLoadPerformanceFailed: false,
      loadingLicenseReportFailed: false,
    };
  },
  computed: {
    shouldRenderLicenseReport() {
      return this.mr?.enabledReports?.licenseScanning;
    },
    hasBrowserPerformanceMetrics() {
      return (
        this.mr.browserPerformanceMetrics?.degraded?.length > 0 ||
        this.mr.browserPerformanceMetrics?.improved?.length > 0 ||
        this.mr.browserPerformanceMetrics?.same?.length > 0
      );
    },
    hasBrowserPerformancePaths() {
      const browserPerformance = this.mr?.browserPerformance || {};

      return Boolean(browserPerformance?.head_path && browserPerformance?.base_path);
    },
    degradedBrowserPerformanceTotalScore() {
      return this.mr?.browserPerformanceMetrics?.degraded.find(
        (metric) => metric.name === __('Total Score'),
      );
    },
    hasBrowserPerformanceDegradation() {
      const threshold = this.mr?.browserPerformance?.degradation_threshold || 0;

      if (!threshold) {
        return true;
      }

      const totalScoreDelta = this.degradedBrowserPerformanceTotalScore?.delta || 0;

      return threshold + totalScoreDelta <= 0;
    },
    hasLoadPerformanceMetrics() {
      return (
        this.mr.loadPerformanceMetrics?.degraded?.length > 0 ||
        this.mr.loadPerformanceMetrics?.improved?.length > 0 ||
        this.mr.loadPerformanceMetrics?.same?.length > 0
      );
    },
    hasLoadPerformancePaths() {
      const loadPerformance = this.mr?.loadPerformance || {};

      return Boolean(loadPerformance.head_path && loadPerformance.base_path);
    },
    shouldRenderBaseSecurityReport() {
      return !this.mr.canReadVulnerabilities && this.shouldRenderSecurityReport;
    },
    shouldRenderExtendedSecurityReport() {
      const { enabledReports } = this.mr;
      return (
        this.mr.canReadVulnerabilities &&
        enabledReports &&
        this.$options.securityReportTypes.some((reportType) => enabledReports[reportType])
      );
    },
    shouldRenderStatusReport() {
      return this.mr?.apiStatusChecksPath && !this.mr?.isNothingToMergeState;
    },
    shouldRenderMetricsReport() {
      return Boolean(this.mr?.metricsReportsPath);
    },
    browserPerformanceText() {
      const { improved, degraded, same } = this.mr.browserPerformanceMetrics;
      const text = [];
      const reportNumbers = [];

      if (improved.length || degraded.length || same.length) {
        text.push(s__('ciReport|Browser performance test metrics: '));

        if (degraded.length > 0)
          reportNumbers.push(
            sprintf(s__('ciReport|%{degradedNum} degraded'), { degradedNum: degraded.length }),
          );
        if (same.length > 0)
          reportNumbers.push(sprintf(s__('ciReport|%{sameNum} same'), { sameNum: same.length }));
        if (improved.length > 0)
          reportNumbers.push(
            sprintf(s__('ciReport|%{improvedNum} improved'), { improvedNum: improved.length }),
          );
      } else {
        text.push(s__('ciReport|Browser performance test metrics: No changes'));
      }

      return [...text, ...reportNumbers.join(', ')].join('');
    },

    loadPerformanceText() {
      const { improved, degraded, same } = this.mr.loadPerformanceMetrics;
      const text = [];
      const reportNumbers = [];

      if (improved.length || degraded.length || same.length) {
        text.push(s__('ciReport|Load performance test metrics: '));

        if (degraded.length > 0)
          reportNumbers.push(
            sprintf(s__('ciReport|%{degradedNum} degraded'), { degradedNum: degraded.length }),
          );
        if (same.length > 0)
          reportNumbers.push(sprintf(s__('ciReport|%{sameNum} same'), { sameNum: same.length }));
        if (improved.length > 0)
          reportNumbers.push(
            sprintf(s__('ciReport|%{improvedNum} improved'), { improvedNum: improved.length }),
          );
      } else {
        text.push(s__('ciReport|Load performance test metrics: No changes'));
      }

      return [...text, ...reportNumbers.join(', ')].join('');
    },

    browserPerformanceStatus() {
      return this.checkReportStatus(
        this.isLoadingBrowserPerformance,
        this.loadingBrowserPerformanceFailed,
      );
    },

    loadPerformanceStatus() {
      return this.checkReportStatus(
        this.isLoadingLoadPerformance,
        this.loadingLoadPerformanceFailed,
      );
    },

    licensesApiPath() {
      return gl?.mrWidgetData?.license_scanning_comparison_path || null;
    },
  },
  watch: {
    hasBrowserPerformancePaths(newVal) {
      if (newVal) {
        this.registerBrowserPerformance();
        this.fetchBrowserPerformance();
      }
    },
    hasLoadPerformancePaths(newVal) {
      if (newVal) {
        this.registerLoadPerformance();
        this.fetchLoadPerformance();
      }
    },
    shouldRenderStatusReport(newVal) {
      if (newVal) {
        this.registerStatusCheck();
      }
    },
    shouldRenderMetricsReport(newVal) {
      if (newVal) {
        this.registerMetrics();
      }
    },
    shouldRenderLicenseReport(newVal) {
      if (newVal) {
        this.registerLicenseCompliance();
      }
    },
  },
  methods: {
    registerLicenseCompliance() {
      registerExtension(licenseComplianceExtension);
    },
    registerLoadPerformance() {
      registerExtension(loadPerformanceExtension);
    },
    registerBrowserPerformance() {
      registerExtension(browserPerformanceExtension);
    },
    registerStatusCheck() {
      registerExtension(statusChecksExtension);
    },
    registerMetrics() {
      registerExtension(metricsExtension);
    },
    getServiceEndpoints(store) {
      const base = CEWidgetOptions.methods.getServiceEndpoints(store);

      return {
        ...base,
        apiApprovalSettingsPath: store.apiApprovalSettingsPath,
      };
    },

    fetchBrowserPerformance() {
      const { head_path, base_path } = this.mr.browserPerformance;

      this.isLoadingBrowserPerformance = true;

      Promise.all([this.service.fetchReport(head_path), this.service.fetchReport(base_path)])
        .then((values) => {
          this.mr.compareBrowserPerformanceMetrics(values[0], values[1]);
        })
        .catch(() => {
          this.loadingBrowserPerformanceFailed = true;
        })
        .finally(() => {
          this.isLoadingBrowserPerformance = false;
        });
    },

    fetchLoadPerformance() {
      const { head_path, base_path } = this.mr.loadPerformance;

      this.isLoadingLoadPerformance = true;

      Promise.all([this.service.fetchReport(head_path), this.service.fetchReport(base_path)])
        .then((values) => {
          this.mr.compareLoadPerformanceMetrics(values[0], values[1]);
        })
        .catch(() => {
          this.loadingLoadPerformanceFailed = true;
        })
        .finally(() => {
          this.isLoadingLoadPerformance = false;
        });
    },

    translateText(type) {
      return {
        error: sprintf(s__('ciReport|Failed to load %{reportName} report'), {
          reportName: type,
        }),
        loading: sprintf(s__('ciReport|Loading %{reportName} report'), {
          reportName: type,
        }),
      };
    },
  },
  // TODO: Use the snake_case report types rather than the camelCased versions
  // of them. See https://gitlab.com/gitlab-org/gitlab/-/issues/282430
  securityReportTypes: [
    'dast',
    'sast',
    'dependencyScanning',
    'containerScanning',
    'coverageFuzzing',
    'apiFuzzing',
    'secretDetection',
  ],
};
</script>
<template>
  <div v-if="!loading" class="mr-state-widget gl-mt-5">
    <header
      v-if="shouldRenderCollaborationStatus"
      class="gl-rounded-base gl-border-solid gl-border-1 gl-border-gray-100 gl-overflow-hidden mr-widget-workflow gl-mt-0!"
    >
      <mr-widget-alert-message v-if="shouldRenderCollaborationStatus" type="info">
        {{ s__('mrWidget|Members who can merge are allowed to add commits.') }}
      </mr-widget-alert-message>
    </header>
    <mr-widget-suggest-pipeline
      v-if="shouldSuggestPipelines"
      class="mr-widget-workflow"
      :pipeline-path="mr.mergeRequestAddCiConfigPath"
      :pipeline-svg-path="mr.pipelinesEmptySvgPath"
      :human-access="formattedHumanAccess"
      :user-callouts-path="mr.userCalloutsPath"
      :user-callout-feature-id="mr.suggestPipelineFeatureId"
      @dismiss="dismissSuggestPipelines"
    />
    <mr-widget-pipeline-container v-if="shouldRenderPipelines" :mr="mr" />
    <mr-widget-approvals v-if="shouldRenderApprovals" :mr="mr" :service="service" />
    <report-widget-container>
      <extensions-container v-if="hasExtensions" :mr="mr" />
      <widget-container v-if="mr && shouldShowSecurityExtension" :mr="mr" />
      <security-reports-app
        v-if="shouldRenderBaseSecurityReport && !shouldShowSecurityExtension"
        :pipeline-id="mr.pipeline.id"
        :project-id="mr.sourceProjectId"
        :security-reports-docs-path="mr.securityReportsDocsPath"
        :sast-comparison-path="mr.sastComparisonPath"
        :secret-detection-comparison-path="mr.secretDetectionComparisonPath"
        :target-project-full-path="mr.targetProjectFullPath"
        :mr-iid="mr.iid"
        :discover-project-security-path="mr.discoverProjectSecurityPath"
      />
      <grouped-security-reports-app
        v-else-if="shouldRenderExtendedSecurityReport && !shouldShowSecurityExtension"
        :head-blob-path="mr.headBlobPath"
        :source-branch="mr.sourceBranch"
        :target-branch="mr.targetBranch"
        :base-blob-path="mr.baseBlobPath"
        :enabled-reports="mr.enabledReports"
        :sast-help-path="mr.sastHelp"
        :dast-help-path="mr.dastHelp"
        :api-fuzzing-help-path="mr.apiFuzzingHelp"
        :coverage-fuzzing-help-path="mr.coverageFuzzingHelp"
        :container-scanning-help-path="mr.containerScanningHelp"
        :dependency-scanning-help-path="mr.dependencyScanningHelp"
        :secret-detection-help-path="mr.secretDetectionHelp"
        :can-read-vulnerability-feedback="mr.canReadVulnerabilityFeedback"
        :vulnerability-feedback-path="mr.vulnerabilityFeedbackPath"
        :create-vulnerability-feedback-issue-path="mr.createVulnerabilityFeedbackIssuePath"
        :create-vulnerability-feedback-merge-request-path="
          mr.createVulnerabilityFeedbackMergeRequestPath
        "
        :create-vulnerability-feedback-dismissal-path="mr.createVulnerabilityFeedbackDismissalPath"
        :pipeline-path="mr.pipeline.path"
        :pipeline-id="mr.securityReportsPipelineId"
        :pipeline-iid="mr.securityReportsPipelineIid"
        :project-id="mr.targetProjectId"
        :project-full-path="mr.sourceProjectFullPath"
        :diverged-commits-count="mr.divergedCommitsCount"
        :mr-state="mr.state"
        :target-branch-tree-path="mr.targetBranchTreePath"
        :new-pipeline-path="mr.newPipelinePath"
        :container-scanning-comparison-path="mr.containerScanningComparisonPath"
        :api-fuzzing-comparison-path="mr.apiFuzzingComparisonPath"
        :coverage-fuzzing-comparison-path="mr.coverageFuzzingComparisonPath"
        :dast-comparison-path="mr.dastComparisonPath"
        :dependency-scanning-comparison-path="mr.dependencyScanningComparisonPath"
        :sast-comparison-path="mr.sastComparisonPath"
        :secret-detection-comparison-path="mr.secretDetectionComparisonPath"
        :target-project-full-path="mr.targetProjectFullPath"
        :mr-iid="mr.iid"
        class="js-security-widget"
      />
    </report-widget-container>
    <div class="mr-section-container mr-widget-workflow">
      <div v-if="hasAlerts" class="gl-overflow-hidden mr-widget-alert-container">
        <mr-widget-alert-message
          v-if="hasMergeError"
          type="danger"
          dismissible
          data-testid="merge_error"
        >
          <span v-safe-html="mergeError"></span>
        </mr-widget-alert-message>
        <mr-widget-alert-message
          v-if="showMergePipelineForkWarning"
          type="warning"
          :help-path="mr.mergeRequestPipelinesHelpPath"
        >
          {{
            s__(
              'mrWidget|If the last pipeline ran in the fork project, it may be inaccurate. Before merge, we advise running a pipeline in this project.',
            )
          }}
          <template #link-content>
            {{ __('Learn more') }}
          </template>
        </mr-widget-alert-message>
      </div>
      <blocking-merge-requests-report :mr="mr" />

      <div class="mr-widget-section">
        <component :is="componentName" :mr="mr" :service="service" />
        <ready-to-merge
          v-if="mr.commitsCount"
          v-show="shouldShowMergeDetails"
          :mr="mr"
          :service="service"
        />
      </div>
    </div>
    <mr-widget-pipeline-container
      v-if="shouldRenderMergedPipeline"
      class="js-post-merge-pipeline mr-widget-workflow"
      :mr="mr"
      :is-post-merge="true"
    />
  </div>
  <loading v-else />
</template>
