<script>
import { mapActions, mapState, mapGetters } from 'vuex';
import { once } from 'lodash';
import { GlButton, GlSprintf, GlLink, GlModalDirective, GlPopover } from '@gitlab/ui';
import { spriteIcon } from '~/lib/utils/common_utils';
import { s__, n__, __, sprintf } from '~/locale';
import { componentNames } from 'ee/ci/reports/components/issue_body';
import { fetchPolicies } from '~/lib/graphql';
import GroupedIssuesList from '~/ci/reports/components/grouped_issues_list.vue';
import ReportSection from '~/ci/reports/components/report_section.vue';
import SummaryRow from '~/ci/reports/components/summary_row.vue';
import { LOADING } from '~/ci/reports/constants';
import { STATUS_CLOSED, STATUS_MERGED } from '~/issues/constants';
import Tracking from '~/tracking';
import MergeRequestArtifactDownload from '~/vue_shared/security_reports/components/artifact_downloads/merge_request_artifact_download.vue';
import SecuritySummary from '~/vue_shared/security_reports/components/security_summary.vue';
import {
  REPORT_TYPE_DAST,
  securityReportTypeEnumToReportType,
  sastPopover,
  containerScanningPopover,
  dastPopover,
  dependencyScanningPopover,
  secretDetectionPopover,
  coverageFuzzingPopover,
  apiFuzzingPopover,
} from 'ee/vue_shared/security_reports/constants';
import { helpPagePath } from '~/helpers/help_page_helper';
import DastModal from './components/dast_modal.vue';
import IssueModal from './components/modal.vue';

import securityReportSummaryQuery from './graphql/mr_security_report_summary.graphql';
import { vulnerabilityModalMixin } from './mixins/vulnerability_modal_mixin';
import createStore from './store';
import {
  MODULE_CONTAINER_SCANNING,
  MODULE_API_FUZZING,
  MODULE_COVERAGE_FUZZING,
  MODULE_DAST,
  MODULE_DEPENDENCY_SCANNING,
  MODULE_SAST,
  MODULE_SECRET_DETECTION,
  trackMrSecurityReportDetails,
} from './store/constants';
import { getSecurityTabPath } from './utils';

export default {
  store: createStore(),
  components: {
    MergeRequestArtifactDownload,
    GroupedIssuesList,
    ReportSection,
    SummaryRow,
    SecuritySummary,
    IssueModal,
    GlSprintf,
    GlLink,
    DastModal,
    GlButton,
    GlPopover,
  },
  directives: {
    'gl-modal': GlModalDirective,
  },
  mixins: [vulnerabilityModalMixin()],
  props: {
    enabledReports: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    headBlobPath: {
      type: String,
      required: true,
    },
    baseBlobPath: {
      type: String,
      required: false,
      default: null,
    },
    sourceBranch: {
      type: String,
      required: false,
      default: null,
    },
    targetBranch: {
      type: String,
      required: false,
      default: null,
    },
    sastHelpPath: {
      type: String,
      required: false,
      default: '',
    },
    containerScanningHelpPath: {
      type: String,
      required: false,
      default: '',
    },
    dastHelpPath: {
      type: String,
      required: false,
      default: '',
    },
    apiFuzzingHelpPath: {
      type: String,
      required: false,
      default: '',
    },
    coverageFuzzingHelpPath: {
      type: String,
      required: false,
      default: '',
    },
    dependencyScanningHelpPath: {
      type: String,
      required: false,
      default: '',
    },
    secretDetectionHelpPath: {
      type: String,
      required: false,
      default: '',
    },
    canReadVulnerabilityFeedback: {
      type: Boolean,
      required: false,
      default: false,
    },
    vulnerabilityFeedbackPath: {
      type: String,
      required: false,
      default: '',
    },
    createVulnerabilityFeedbackIssuePath: {
      type: String,
      required: false,
      default: '',
    },
    createVulnerabilityFeedbackMergeRequestPath: {
      type: String,
      required: false,
      default: '',
    },
    createVulnerabilityFeedbackDismissalPath: {
      type: String,
      required: false,
      default: '',
    },
    pipelineId: {
      type: Number,
      required: false,
      default: null,
    },
    pipelineIid: {
      type: Number,
      required: false,
      default: null,
    },
    pipelinePath: {
      type: String,
      required: false,
      default: undefined,
    },
    divergedCommitsCount: {
      type: Number,
      required: false,
      default: 0,
    },
    mrState: {
      type: String,
      required: false,
      default: null,
    },
    targetBranchTreePath: {
      type: String,
      required: false,
      default: '',
    },
    newPipelinePath: {
      type: String,
      required: false,
      default: '',
    },
    projectId: {
      type: Number,
      required: false,
      default: null,
    },
    projectFullPath: {
      type: String,
      required: true,
    },
    apiFuzzingComparisonPath: {
      type: String,
      required: false,
      default: '',
    },
    containerScanningComparisonPath: {
      type: String,
      required: false,
      default: '',
    },
    coverageFuzzingComparisonPath: {
      type: String,
      required: false,
      default: '',
    },
    dastComparisonPath: {
      type: String,
      required: false,
      default: '',
    },
    dependencyScanningComparisonPath: {
      type: String,
      required: false,
      default: '',
    },
    sastComparisonPath: {
      type: String,
      required: false,
      default: '',
    },
    secretDetectionComparisonPath: {
      type: String,
      required: false,
      default: '',
    },
    targetProjectFullPath: {
      type: String,
      required: true,
    },
    mrIid: {
      type: Number,
      required: true,
    },
  },
  apollo: {
    dastSummary: {
      query: securityReportSummaryQuery,
      fetchPolicy: fetchPolicies.NETWORK_ONLY,
      variables() {
        return {
          fullPath: this.projectFullPath,
          pipelineIid: this.pipelineIid,
        };
      },
      update(data) {
        const dast = data?.project?.pipeline?.securityReportSummary?.dast;
        return dast && Object.keys(dast).length ? dast : null;
      },
    },
  },
  i18n: {
    sastPopover,
    containerScanningPopover,
    dastPopover,
    dependencyScanningPopover,
    secretDetectionPopover,
    coverageFuzzingPopover,
    apiFuzzingPopover,
    scannedResources: s__('SecurityReports|scanned resources'),
    fullReport: s__('ciReport|Full report'),
    divergedFromTargetBranch: __(
      'Security report is out of date. Please update your branch with the latest changes from the target branch (%{targetBranchName})',
    ),
    baseSecurityReportOutOfDate: __(
      'Security report is out of date. Run %{newPipelineLinkStart}a new pipeline%{newPipelineLinkEnd} for the target branch (%{targetBranchName})',
    ),
    viewDetails: __('View details'),
    scannedUrls: (count) => n__('%d URL scanned', '%d URLs scanned', count),
    infoPopover: {
      title: s__('SecurityReports|Security scan results'),
      description: s__(
        'SecurityReports|New vulnerabilities are vulnerabilities that the security scan detects in the merge request that are different to existing vulnerabilities in the default branch.',
      ),
    },
  },
  componentNames,
  computed: {
    ...mapState([
      MODULE_SAST,
      MODULE_CONTAINER_SCANNING,
      MODULE_DAST,
      MODULE_API_FUZZING,
      MODULE_COVERAGE_FUZZING,
      MODULE_DEPENDENCY_SCANNING,
      MODULE_SECRET_DETECTION,
      'summaryCounts',
      'modal',
      'isCreatingIssue',
      'isDismissingVulnerability',
      'isCreatingMergeRequest',
    ]),
    ...mapGetters([
      'groupedSummaryText',
      'summaryStatus',
      'groupedContainerScanningText',
      'groupedDastText',
      'groupedDependencyText',
      'groupedCoverageFuzzingText',
      'containerScanningStatusIcon',
      'dastStatusIcon',
      'dependencyScanningStatusIcon',
      'coverageFuzzingStatusIcon',
      'isBaseSecurityReportOutOfDate',
      'canCreateIssue',
      'canDismissVulnerability',
    ]),
    ...mapGetters(MODULE_SAST, ['groupedSastText', 'sastStatusIcon']),
    ...mapGetters(MODULE_SECRET_DETECTION, [
      'groupedSecretDetectionText',
      'secretDetectionStatusIcon',
    ]),
    ...mapGetters(MODULE_API_FUZZING, ['groupedApiFuzzingText', 'apiFuzzingStatusIcon']),
    securityTab() {
      return getSecurityTabPath(this.pipelinePath);
    },
    hasContainerScanningReports() {
      return this.enabledReports.containerScanning;
    },
    hasDependencyScanningReports() {
      return this.enabledReports.dependencyScanning;
    },
    hasDastReports() {
      return this.enabledReports.dast;
    },
    hasApiFuzzingReports() {
      return this.enabledReports.apiFuzzing;
    },
    hasCoverageFuzzingReports() {
      return this.enabledReports.coverageFuzzing;
    },
    hasSastReports() {
      return this.enabledReports.sast;
    },
    hasSecretDetectionReports() {
      return this.enabledReports.secretDetection;
    },
    isMRActive() {
      return this.mrState !== STATUS_MERGED && this.mrState !== STATUS_CLOSED;
    },
    hasDivergedFromTargetBranch() {
      return this.divergedCommitsCount > 0;
    },
    hasDastScannedResources() {
      return this.dastSummary?.scannedResourcesCount > 0;
    },
    handleToggleEvent() {
      return once(() => {
        const { category, action } = trackMrSecurityReportDetails;
        Tracking.event(category, action);
      });
    },
    dastDownloadLink() {
      return this.dastSummary?.scannedResourcesCsvPath || '';
    },
    hasApiFuzzingIssues() {
      return this.hasIssuesForReportType(MODULE_API_FUZZING);
    },
    hasCoverageFuzzingIssues() {
      return this.hasIssuesForReportType(MODULE_COVERAGE_FUZZING);
    },
    hasSastIssues() {
      return this.hasIssuesForReportType(MODULE_SAST);
    },
    hasDependencyScanningIssues() {
      return this.hasIssuesForReportType(MODULE_DEPENDENCY_SCANNING);
    },
    hasContainerScanningIssues() {
      return this.hasIssuesForReportType(MODULE_CONTAINER_SCANNING);
    },
    hasDastIssues() {
      return this.hasIssuesForReportType(MODULE_DAST);
    },
    hasSecretDetectionIssues() {
      return this.hasIssuesForReportType(MODULE_SECRET_DETECTION);
    },
    shouldShowDownloadGuidance() {
      return this.targetProjectFullPath && this.mrIid && this.summaryStatus !== LOADING;
    },
    dastCsvArtifacts() {
      return [
        {
          name: this.$options.i18n.scannedResources,
          path: this.dastDownloadLink,
          reportType: REPORT_TYPE_DAST,
        },
      ];
    },
  },

  created() {
    this.setHeadBlobPath(this.headBlobPath);
    this.setBaseBlobPath(this.baseBlobPath);
    this.setSourceBranch(this.sourceBranch);

    this.setCanReadVulnerabilityFeedback(this.canReadVulnerabilityFeedback);
    this.setVulnerabilityFeedbackPath(this.vulnerabilityFeedbackPath);
    this.setCreateVulnerabilityFeedbackIssuePath(this.createVulnerabilityFeedbackIssuePath);
    this.setCreateVulnerabilityFeedbackMergeRequestPath(
      this.createVulnerabilityFeedbackMergeRequestPath,
    );
    this.setCreateVulnerabilityFeedbackDismissalPath(this.createVulnerabilityFeedbackDismissalPath);
    this.setProjectId(this.projectId);
    this.setPipelineId(this.pipelineId);
    this.setPipelineJobsId(this.pipelineId);

    if (this.sastComparisonPath && this.hasSastReports) {
      this.setSastDiffEndpoint(this.sastComparisonPath);
      this.fetchSecurityReport(this.fetchSastDiff, 'sast');
    }

    if (this.containerScanningComparisonPath && this.hasContainerScanningReports) {
      this.setContainerScanningDiffEndpoint(this.containerScanningComparisonPath);
      this.fetchSecurityReport(this.fetchContainerScanningDiff, 'container_scanning');
    }

    if (this.dastComparisonPath && this.hasDastReports) {
      this.setDastDiffEndpoint(this.dastComparisonPath);
      this.fetchSecurityReport(this.fetchDastDiff, 'dast');
    }

    if (this.dependencyScanningComparisonPath && this.hasDependencyScanningReports) {
      this.setDependencyScanningDiffEndpoint(this.dependencyScanningComparisonPath);
      this.fetchSecurityReport(this.fetchDependencyScanningDiff, 'dependency_scanning');
    }

    if (this.secretDetectionComparisonPath && this.hasSecretDetectionReports) {
      this.setSecretDetectionDiffEndpoint(this.secretDetectionComparisonPath);
      this.fetchSecurityReport(this.fetchSecretDetectionDiff, 'secret_detection');
    }

    if (this.coverageFuzzingComparisonPath && this.hasCoverageFuzzingReports) {
      this.setCoverageFuzzingDiffEndpoint(this.coverageFuzzingComparisonPath);
      this.fetchSecurityReport(this.fetchCoverageFuzzingDiff, 'coverage_fuzzing');
      this.fetchPipelineJobs();
    }

    if (this.apiFuzzingComparisonPath && this.hasApiFuzzingReports) {
      this.setApiFuzzingDiffEndpoint(this.apiFuzzingComparisonPath);
      this.fetchSecurityReport(this.fetchApiFuzzingDiff, 'api_fuzzing');
    }
  },
  methods: {
    ...mapActions([
      'setAppType',
      'setHeadBlobPath',
      'setBaseBlobPath',
      'setSourceBranch',
      'setCanReadVulnerabilityFeedback',
      'setVulnerabilityFeedbackPath',
      'setCreateVulnerabilityFeedbackIssuePath',
      'setCreateVulnerabilityFeedbackMergeRequestPath',
      'setCreateVulnerabilityFeedbackDismissalPath',
      'setPipelineId',
      'createNewIssue',
      'createMergeRequest',
      'openDismissalCommentBox',
      'closeDismissalCommentBox',
      'downloadPatch',
      'showDismissalDeleteButtons',
      'hideDismissalDeleteButtons',
      'fetchContainerScanningDiff',
      'setContainerScanningDiffEndpoint',
      'fetchDependencyScanningDiff',
      'setDependencyScanningDiffEndpoint',
      'fetchDastDiff',
      'setDastDiffEndpoint',
      'fetchCoverageFuzzingDiff',
      'setCoverageFuzzingDiffEndpoint',
    ]),
    ...mapActions(MODULE_SAST, {
      setSastDiffEndpoint: 'setDiffEndpoint',
      fetchSastDiff: 'fetchDiff',
    }),
    ...mapActions(MODULE_SECRET_DETECTION, {
      setSecretDetectionDiffEndpoint: 'setDiffEndpoint',
      fetchSecretDetectionDiff: 'fetchDiff',
    }),
    ...mapActions(MODULE_API_FUZZING, {
      setApiFuzzingDiffEndpoint: 'setDiffEndpoint',
      fetchApiFuzzingDiff: 'fetchDiff',
    }),
    ...mapActions('pipelineJobs', ['fetchPipelineJobs', 'setPipelineJobsPath', 'setProjectId']),
    ...mapActions('pipelineJobs', {
      setPipelineJobsId: 'setPipelineId',
    }),
    hasIssuesForReportType(reportType) {
      return Boolean(this[reportType]?.newIssues.length || this[reportType]?.resolvedIssues.length);
    },
    async fetchSecurityReport(fetchFn, toolName) {
      try {
        const reports = await fetchFn();
        const category = 'Vulnerability_Management';
        const eventNameFixed = `mr_widget_findings_counts_${toolName}_fixed`;
        const eventNameAdded = `mr_widget_findings_counts_${toolName}_added`;

        Tracking.event(category, eventNameFixed, {
          value: reports?.diff?.fixed?.length || 0,
        });

        Tracking.event(category, eventNameAdded, {
          value: reports?.diff?.added?.length || 0,
        });
      } catch {
        // Do nothing, we dispatch an error message in the action
      }
    },
    getPopover(popoverContent, url) {
      return {
        title: popoverContent.title,
        content: sprintf(
          popoverContent.copy,
          {
            linkStartTag: `<a href="${url}" target="_blank" rel="noopener noreferrer">`,
            linkEndTag: `${spriteIcon('external-link', 's16')}</a>`,
          },
          false,
        ),
      };
    },
  },
  summarySlots: ['success', 'error', 'loading'],
  reportTypes: {
    API_FUZZING: [securityReportTypeEnumToReportType.API_FUZZING],
    COVERAGE_FUZZING: [securityReportTypeEnumToReportType.COVERAGE_FUZZING],
    DAST: [securityReportTypeEnumToReportType.DAST],
  },
  infoPopoverHelpPagePath: helpPagePath('user/application_security/index', {
    anchor: 'ultimate',
  }),
};
</script>
<template>
  <report-section
    :status="summaryStatus"
    :has-issues="true"
    :should-emit-toggle-event="true"
    class="mr-widget-border-top grouped-security-reports mr-report"
    track-action="users_expanding_secure_security_report"
    @toggleEvent="handleToggleEvent"
  >
    <template v-for="slot in $options.summarySlots" #[slot]>
      <security-summary :key="slot" :message="groupedSummaryText" />
    </template>

    <template #action-buttons>
      <div class="gl-mr-3">
        <gl-button ref="infoButton" data-testid="info-button" variant="link" icon="information-o" />
        <gl-popover :target="() => $refs.infoButton.$el">
          <template #title>
            {{ $options.i18n.infoPopover.title }}
          </template>
          {{ $options.i18n.infoPopover.description }}
          <gl-link
            class="gl-display-inline-block gl-reset-font-size"
            :href="$options.infoPopoverHelpPagePath"
          >
            {{ __('Learn more') }}
          </gl-link>
        </gl-popover>
      </div>

      <gl-button
        v-if="pipelinePath"
        :href="securityTab"
        target="_blank"
        class="report-btn"
        category="tertiary"
        variant="info"
        size="small"
      >
        {{ $options.i18n.fullReport }}
      </gl-button>
    </template>

    <template v-if="isMRActive" #sub-heading>
      <div class="gl-text-gray-700 gl-font-sm">
        <gl-sprintf
          v-if="hasDivergedFromTargetBranch"
          :message="$options.i18n.divergedFromTargetBranch"
        >
          <template #targetBranchName>
            <gl-link class="gl-font-sm" :href="targetBranchTreePath">{{ targetBranch }}</gl-link>
          </template>
        </gl-sprintf>

        <gl-sprintf
          v-else-if="isBaseSecurityReportOutOfDate"
          :message="$options.i18n.baseSecurityReportOutOfDate"
        >
          <template #newPipelineLink="{ content }">
            <gl-link class="gl-font-sm" :href="`${newPipelinePath}?ref=${targetBranch}`">{{
              content
            }}</gl-link>
          </template>
          <template #targetBranchName>
            <gl-link class="gl-font-sm" :href="targetBranchTreePath">{{ targetBranch }}</gl-link>
          </template>
        </gl-sprintf>
      </div>
    </template>

    <template #body>
      <div class="mr-widget-grouped-section report-block">
        <template v-if="hasSastReports">
          <summary-row
            :nested-summary="true"
            :status-icon="sastStatusIcon"
            :popover-options="getPopover($options.i18n.sastPopover, sastHelpPath)"
            class="js-sast-widget"
            data-qa-selector="sast_scan_report"
          >
            <template #summary>
              <security-summary :message="groupedSastText" />
            </template>
          </summary-row>

          <grouped-issues-list
            v-if="hasSastIssues"
            :nested-level="2"
            :unresolved-issues="sast.newIssues"
            :resolved-issues="sast.resolvedIssues"
            :component="$options.componentNames.SecurityIssueBody"
            data-testid="sast-issues-list"
          />
        </template>

        <template v-if="hasDependencyScanningReports">
          <summary-row
            :nested-summary="true"
            :status-icon="dependencyScanningStatusIcon"
            :popover-options="
              getPopover($options.i18n.dependencyScanningPopover, dependencyScanningHelpPath)
            "
            class="js-dependency-scanning-widget"
            data-qa-selector="dependency_scan_report"
          >
            <template #summary>
              <security-summary :message="groupedDependencyText" />
            </template>
          </summary-row>

          <grouped-issues-list
            v-if="hasDependencyScanningIssues"
            :nested-level="2"
            :unresolved-issues="dependencyScanning.newIssues"
            :resolved-issues="dependencyScanning.resolvedIssues"
            :component="$options.componentNames.SecurityIssueBody"
            data-testid="dependency-scanning-issues-list"
          />
        </template>

        <template v-if="hasContainerScanningReports">
          <summary-row
            :nested-summary="true"
            :status-icon="containerScanningStatusIcon"
            :popover-options="
              getPopover($options.i18n.containerScanningPopover, containerScanningHelpPath)
            "
            class="js-container-scanning"
            data-qa-selector="container_scan_report"
          >
            <template #summary>
              <security-summary :message="groupedContainerScanningText" />
            </template>
          </summary-row>

          <grouped-issues-list
            v-if="hasContainerScanningIssues"
            :nested-level="2"
            :unresolved-issues="containerScanning.newIssues"
            :resolved-issues="containerScanning.resolvedIssues"
            :component="$options.componentNames.SecurityIssueBody"
            data-testid="container-scanning-issues-list"
          />
        </template>

        <template v-if="hasDastReports">
          <summary-row
            :nested-summary="true"
            :status-icon="dastStatusIcon"
            :popover-options="getPopover($options.i18n.dastPopover, dastHelpPath)"
            class="js-dast-widget"
            data-qa-selector="dast_scan_report"
          >
            <template #summary>
              <security-summary :message="groupedDastText" />
            </template>

            <template v-if="hasDastScannedResources">
              <div class="text-nowrap">
                {{ $options.i18n.scannedUrls(dastSummary.scannedResourcesCount) }}
              </div>
              <gl-link v-gl-modal.dastUrl class="ml-2" data-testid="dast-ci-job-link">
                {{ $options.i18n.viewDetails }}
              </gl-link>
              <dast-modal
                :scanned-urls="dastSummary.scannedResources.nodes"
                :scanned-resources-count="dastSummary.scannedResourcesCount"
                :download-link="dastDownloadLink"
              />
            </template>
            <template v-else-if="dastDownloadLink">
              <merge-request-artifact-download
                v-if="shouldShowDownloadGuidance"
                :report-types="$options.reportTypes.DAST"
                :target-project-full-path="targetProjectFullPath"
                :mr-iid="mrIid"
                :injected-artifacts="dastCsvArtifacts"
                data-testid="download-link"
              />
            </template>
          </summary-row>
          <grouped-issues-list
            v-if="hasDastIssues"
            :nested-level="2"
            :unresolved-issues="dast.newIssues"
            :resolved-issues="dast.resolvedIssues"
            :component="$options.componentNames.SecurityIssueBody"
            data-testid="dast-issues-list"
          />
        </template>

        <template v-if="hasSecretDetectionReports">
          <summary-row
            :nested-summary="true"
            :status-icon="secretDetectionStatusIcon"
            :popover-options="
              getPopover($options.i18n.secretDetectionPopover, secretDetectionHelpPath)
            "
            class="js-secret-detection"
            data-testid="secret-detection-report"
          >
            <template #summary>
              <security-summary :message="groupedSecretDetectionText" />
            </template>
          </summary-row>

          <grouped-issues-list
            v-if="hasSecretDetectionIssues"
            :nested-level="2"
            :unresolved-issues="secretDetection.newIssues"
            :resolved-issues="secretDetection.resolvedIssues"
            :component="$options.componentNames.SecurityIssueBody"
            data-testid="secret-detection-issues-list"
          />
        </template>

        <template v-if="hasCoverageFuzzingReports">
          <summary-row
            :nested-summary="true"
            :status-icon="coverageFuzzingStatusIcon"
            :popover-options="
              getPopover($options.i18n.coverageFuzzingPopover, coverageFuzzingHelpPath)
            "
            class="js-coverage-fuzzing-widget"
            data-qa-selector="coverage_fuzzing_report"
          >
            <template #summary>
              <security-summary :message="groupedCoverageFuzzingText" />
            </template>
            <merge-request-artifact-download
              v-if="shouldShowDownloadGuidance"
              :report-types="$options.reportTypes.COVERAGE_FUZZING"
              :target-project-full-path="targetProjectFullPath"
              :mr-iid="mrIid"
            />
          </summary-row>

          <grouped-issues-list
            v-if="hasCoverageFuzzingIssues"
            :nested-level="2"
            :unresolved-issues="coverageFuzzing.newIssues"
            :resolved-issues="coverageFuzzing.resolvedIssues"
            :component="$options.componentNames.SecurityIssueBody"
            data-testid="coverage-fuzzing-issues-list"
          />
        </template>

        <template v-if="hasApiFuzzingReports">
          <summary-row
            :nested-summary="true"
            :status-icon="apiFuzzingStatusIcon"
            :popover-options="getPopover($options.i18n.apiFuzzingPopover, apiFuzzingHelpPath)"
            class="js-api-fuzzing-widget"
            data-qa-selector="api_fuzzing_report"
          >
            <template #summary>
              <security-summary :message="groupedApiFuzzingText" />
            </template>

            <merge-request-artifact-download
              v-if="shouldShowDownloadGuidance"
              :report-types="$options.reportTypes.API_FUZZING"
              :target-project-full-path="targetProjectFullPath"
              :mr-iid="mrIid"
            />
          </summary-row>

          <grouped-issues-list
            v-if="hasApiFuzzingIssues"
            :nested-level="2"
            :unresolved-issues="apiFuzzing.newIssues"
            :resolved-issues="apiFuzzing.resolvedIssues"
            :component="$options.componentNames.SecurityIssueBody"
            class="report-block-group-list"
            data-testid="api-fuzzing-issues-list"
          />
        </template>

        <issue-modal
          :modal="modal"
          :can-create-issue="canCreateIssue"
          :can-dismiss-vulnerability="canDismissVulnerability"
          :is-creating-issue="isCreatingIssue"
          :is-dismissing-vulnerability="isDismissingVulnerability"
          :is-creating-merge-request="isCreatingMergeRequest"
          @closeDismissalCommentBox="closeDismissalCommentBox()"
          @createMergeRequest="createMergeRequest"
          @createNewIssue="createNewIssue"
          @dismissVulnerability="handleDismissVulnerability"
          @openDismissalCommentBox="openDismissalCommentBox()"
          @editVulnerabilityDismissalComment="openDismissalCommentBox()"
          @revertDismissVulnerability="handleRevertDismissVulnerability"
          @downloadPatch="downloadPatch"
          @addDismissalComment="handleAddDismissalComment({ comment: $event })"
          @deleteDismissalComment="handleDeleteDismissalComment"
          @showDismissalDeleteButtons="showDismissalDeleteButtons"
          @hideDismissalDeleteButtons="hideDismissalDeleteButtons"
        />
      </div>
    </template>
  </report-section>
</template>
