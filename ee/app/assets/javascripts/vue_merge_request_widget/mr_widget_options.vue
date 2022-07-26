<script>
import { GlSprintf, GlLink, GlSafeHtmlDirective } from '@gitlab/ui';
import MrWidgetLicenses from 'ee/vue_shared/license_compliance/mr_widget_license_report.vue';
import reportsMixin from 'ee/vue_shared/security_reports/mixins/reports_mixin';
import { registerExtension } from '~/vue_merge_request_widget/components/extensions';
import { s__, __, sprintf } from '~/locale';
import CEWidgetOptions from '~/vue_merge_request_widget/mr_widget_options.vue';
import MrWidgetEnableFeaturePrompt from './components/states/mr_widget_enable_feature_prompt.vue';
import MrWidgetJiraAssociationMissing from './components/states/mr_widget_jira_association_missing.vue';
import MrWidgetPolicyViolation from './components/states/mr_widget_policy_violation.vue';
import MrWidgetGeoSecondaryNode from './components/states/mr_widget_secondary_geo_node.vue';
import loadPerformanceExtension from './extensions/load_performance';
import browserPerformanceExtension from './extensions/browser_performance';
import statusChecksExtension from './extensions/status_checks';
import metricsExtension from './extensions/metrics';
import licenseComplianceExtension from './extensions/license_compliance';

export default {
  components: {
    GlSprintf,
    GlLink,
    MrWidgetLicenses,
    MrWidgetGeoSecondaryNode,
    MrWidgetPolicyViolation,
    MrWidgetEnableFeaturePrompt,
    MrWidgetJiraAssociationMissing,
    StatusChecksReportsApp: () =>
      import('ee/reports/status_checks_report/status_checks_reports_app.vue'),
    BlockingMergeRequestsReport: () =>
      import('./components/blocking_merge_requests/blocking_merge_requests_report.vue'),
    GroupedSecurityReportsApp: () =>
      import('ee/vue_shared/security_reports/grouped_security_reports_app.vue'),
    GroupedMetricsReportsApp: () =>
      import('ee/vue_shared/metrics_reports/grouped_metrics_reports_app.vue'),
    GroupedBrowserPerformanceReportsApp: () =>
      import('ee/reports/browser_performance_report/grouped_browser_performance_reports_app.vue'),
    GroupedLoadPerformanceReportsApp: () =>
      import('ee/reports/load_performance_report/grouped_load_performance_reports_app.vue'),
    ReportSection: () => import('~/reports/components/report_section.vue'),
  },
  directives: {
    SafeHtml: GlSafeHtmlDirective,
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
    shouldRenderBrowserPerformance() {
      return (
        this.hasBrowserPerformancePaths &&
        this.hasBrowserPerformanceDegradation &&
        !this.shouldShowExtension
      );
    },
    shouldShowLicenseComplianceExtension() {
      return window.gon?.features?.refactorLicenseComplianceExtension;
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
      if (this.shouldShowLicenseComplianceExtension) {
        registerExtension(licenseComplianceExtension);
      }
    },
    registerLoadPerformance() {
      if (this.shouldShowExtension) {
        registerExtension(loadPerformanceExtension);
      }
    },
    registerBrowserPerformance() {
      if (this.shouldShowExtension) {
        registerExtension(browserPerformanceExtension);
      }
    },
    registerStatusCheck() {
      if (this.shouldShowExtension) {
        registerExtension(statusChecksExtension);
      }
    },
    registerMetrics() {
      if (this.shouldShowExtension) {
        registerExtension(metricsExtension);
      }
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
  <div v-if="isLoaded" class="mr-state-widget gl-mt-3">
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
    <mr-widget-pipeline-container
      v-if="shouldRenderPipelines"
      class="mr-widget-workflow"
      :mr="mr"
    />
    <mr-widget-approvals
      v-if="shouldRenderApprovals"
      class="mr-widget-workflow"
      :mr="mr"
      :service="service"
    />
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
      <extensions-container :mr="mr" />
      <blocking-merge-requests-report :mr="mr" />
      <grouped-codequality-reports-app
        v-if="shouldRenderCodeQuality && !shouldShowCodeQualityExtension"
        :head-blob-path="mr.headBlobPath"
        :base-blob-path="mr.baseBlobPath"
        :codequality-reports-path="mr.codequalityReportsPath"
        :codequality-help-path="mr.codequalityHelpPath"
      />
      <grouped-browser-performance-reports-app
        v-if="shouldRenderBrowserPerformance && !shouldShowExtension"
        :status="browserPerformanceStatus"
        :loading-text="translateText('browser-performance').loading"
        :error-text="translateText('browser-performance').error"
        :success-text="browserPerformanceText"
        :unresolved-issues="mr.browserPerformanceMetrics.degraded"
        :resolved-issues="mr.browserPerformanceMetrics.improved"
        :neutral-issues="mr.browserPerformanceMetrics.same"
        :has-issues="hasBrowserPerformanceMetrics"
      />
      <grouped-load-performance-reports-app
        v-if="hasLoadPerformancePaths && !shouldShowExtension"
        :status="loadPerformanceStatus"
        :loading-text="translateText('load-performance').loading"
        :error-text="translateText('load-performance').error"
        :success-text="loadPerformanceText"
        :unresolved-issues="mr.loadPerformanceMetrics.degraded"
        :resolved-issues="mr.loadPerformanceMetrics.improved"
        :neutral-issues="mr.loadPerformanceMetrics.same"
        :has-issues="hasLoadPerformanceMetrics"
      />
      <grouped-metrics-reports-app
        v-if="mr.metricsReportsPath && !shouldShowExtension"
        :endpoint="mr.metricsReportsPath"
        class="js-metrics-reports-container"
      />

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
      <mr-widget-enable-feature-prompt
        v-else-if="mr.canReadVulnerabilities"
        feature="security_reports_mr_widget_prompt"
      >
        {{ s__('mrWidget|SAST and Secret Detection is not enabled.') }}
        <gl-sprintf
          :message="
            s__(
              'mrWidget|%{linkStart}Set up now%{linkEnd} to analyze your source code for known security vulnerabilities.',
            )
          "
        >
          <template #link="{ content }">
            <gl-link
              href="../security/configuration"
              target="_blank"
              rel="noopener noreferrer"
              data-track-action="followed"
              data-track-experiment="security_reports_mr_widget_prompt"
              >{{ content }}</gl-link
            >
          </template>
        </gl-sprintf>
      </mr-widget-enable-feature-prompt>

      <mr-widget-licenses
        v-if="shouldRenderLicenseReport && !shouldShowLicenseComplianceExtension"
        :api-url="mr.licenseScanning.managed_licenses_path"
        :approvals-api-path="mr.apiApprovalsPath"
        :licenses-api-path="licensesApiPath"
        :pipeline-path="mr.pipeline.path"
        :can-manage-licenses="mr.licenseScanning.can_manage_licenses"
        :full-report-path="mr.licenseScanning.full_report_path"
        :license-management-settings-path="mr.licenseScanning.settings_path"
        :license-compliance-docs-path="mr.licenseComplianceDocsPath"
        report-section-class="mr-widget-border-top"
      />

      <grouped-test-reports-app
        v-if="shouldRenderTestReport && !shouldRenderRefactoredTestReport"
        class="js-reports-container"
        :endpoint="mr.testResultsPath"
        :head-blob-path="mr.headBlobPath"
        :pipeline-path="mr.pipeline.path"
      />

      <terraform-plan
        v-if="mr.terraformReportsPath && !shouldShowExtension"
        :endpoint="mr.terraformReportsPath"
      />

      <grouped-accessibility-reports-app
        v-if="shouldShowAccessibilityReport && !shouldShowExtension"
        :endpoint="mr.accessibilityReportPath"
      />

      <status-checks-reports-app
        v-if="shouldRenderStatusReport && !shouldShowExtension"
        :endpoint="mr.apiStatusChecksPath"
      />

      <div class="mr-widget-section">
        <component :is="componentName" :mr="mr" :service="service" />
        <ready-to-merge v-if="mr.commitsCount" :mr="mr" :service="service" />
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
