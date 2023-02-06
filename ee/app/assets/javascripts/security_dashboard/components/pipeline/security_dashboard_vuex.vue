<script>
import { mapActions, mapState, mapGetters } from 'vuex';
import IssueModal from 'ee/vue_shared/security_reports/components/modal.vue';
import { vulnerabilityModalMixin } from 'ee/vue_shared/security_reports/mixins/vulnerability_modal_mixin';
import { setupStore } from '../../store';
import VulnerabilityReportLayout from '../shared/vulnerability_report_layout.vue';
import Filters from './filters.vue';
import LoadingError from './loading_error.vue';
import SecurityDashboardTable from './security_dashboard_table.vue';

export default {
  components: {
    Filters,
    IssueModal,
    VulnerabilityReportLayout,
    SecurityDashboardTable,
    LoadingError,
  },
  mixins: [vulnerabilityModalMixin('vulnerabilities')],
  inject: ['pipeline', 'projectId'],
  props: {
    vulnerabilitiesEndpoint: {
      type: String,
      required: true,
    },
    pipelineId: {
      type: Number,
      required: false,
      default: null,
    },
    securityReportSummary: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    loadingErrorIllustrations: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    ...mapState('vulnerabilities', [
      'modal',
      'pageInfo',
      'loadingVulnerabilitiesErrorCode',
      'isCreatingIssue',
      'isDismissingVulnerability',
      'isCreatingMergeRequest',
    ]),
    ...mapState('pipelineJobs', ['projectId']),
    ...mapState('filters', ['filters']),
    ...mapGetters('vulnerabilities', ['loadingVulnerabilitiesFailedWithRecognizedErrorCode']),
    canCreateIssue() {
      const gitLabIssuePath = this.vulnerability.create_vulnerability_feedback_issue_path;
      const jiraIssueUrl = this.vulnerability.create_jira_issue_url;

      return Boolean(gitLabIssuePath || jiraIssueUrl);
    },
    canDismissVulnerability() {
      const path = this.vulnerability.create_vulnerability_feedback_dismissal_path;
      return Boolean(path);
    },
    vulnerability() {
      return this.modal.vulnerability;
    },
  },
  created() {
    setupStore(this.$store);
    this.setSourceBranch(this.pipeline.sourceBranch);
    this.setPipelineJobsPath(this.pipeline.jobsPath);
    this.setProjectId(this.projectId);
    this.setPipelineId(this.pipelineId);
    this.setVulnerabilitiesEndpoint(this.vulnerabilitiesEndpoint);
    this.fetchPipelineJobs();
  },
  methods: {
    ...mapActions('vulnerabilities', [
      'setSourceBranch',
      'closeDismissalCommentBox',
      'createIssue',
      'createMergeRequest',
      'openDismissalCommentBox',
      'setPipelineId',
      'setVulnerabilitiesEndpoint',
      'showDismissalDeleteButtons',
      'hideDismissalDeleteButtons',
      'downloadPatch',
    ]),
    ...mapActions('pipelineJobs', ['setPipelineJobsPath', 'setProjectId', 'fetchPipelineJobs']),
    ...mapActions('filters', ['lockFilter', 'setHideDismissedToggleInitialState']),
  },
};
</script>

<template>
  <section>
    <loading-error
      v-if="loadingVulnerabilitiesFailedWithRecognizedErrorCode"
      :error-code="loadingVulnerabilitiesErrorCode"
      :illustrations="loadingErrorIllustrations"
    />
    <template v-else>
      <vulnerability-report-layout>
        <template #header>
          <filters />
        </template>

        <security-dashboard-table>
          <template #empty-state>
            <slot name="empty-state"></slot>
          </template>
        </security-dashboard-table>
      </vulnerability-report-layout>

      <issue-modal
        :modal="modal"
        :can-create-issue="canCreateIssue"
        :can-dismiss-vulnerability="canDismissVulnerability"
        :is-creating-issue="isCreatingIssue"
        :is-dismissing-vulnerability="isDismissingVulnerability"
        :is-creating-merge-request="isCreatingMergeRequest"
        @addDismissalComment="handleAddDismissalComment({ vulnerability, comment: $event })"
        @editVulnerabilityDismissalComment="openDismissalCommentBox"
        @showDismissalDeleteButtons="showDismissalDeleteButtons"
        @hideDismissalDeleteButtons="hideDismissalDeleteButtons"
        @deleteDismissalComment="handleDeleteDismissalComment({ vulnerability })"
        @closeDismissalCommentBox="closeDismissalCommentBox"
        @createMergeRequest="createMergeRequest({ vulnerability })"
        @createNewIssue="createIssue({ vulnerability })"
        @dismissVulnerability="handleDismissVulnerability({ vulnerability, comment: $event })"
        @openDismissalCommentBox="openDismissalCommentBox"
        @revertDismissVulnerability="handleRevertDismissVulnerability({ vulnerability })"
        @downloadPatch="downloadPatch({ vulnerability })"
      />
    </template>
  </section>
</template>
