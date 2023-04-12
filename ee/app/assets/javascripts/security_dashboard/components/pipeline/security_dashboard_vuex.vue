<script>
import { mapActions, mapState, mapGetters } from 'vuex';
import IssueModal from 'ee/vue_shared/security_reports/components/modal.vue';
import VulnerabilityFindingModal from 'ee/security_dashboard/components/pipeline/vulnerability_finding_modal.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { vulnerabilityModalMixin } from 'ee/vue_shared/security_reports/mixins/vulnerability_modal_mixin';
import { BV_SHOW_MODAL } from '~/lib/utils/constants';
import { VULNERABILITY_MODAL_ID } from 'ee/vue_shared/security_reports/components/constants';
import { setupStore } from '../../store';
import VulnerabilityReportLayout from '../shared/vulnerability_report_layout.vue';
import Filters from './filters.vue';
import LoadingError from './loading_error.vue';
import SecurityDashboardTable from './security_dashboard_table.vue';

export default {
  components: {
    Filters,
    IssueModal,
    VulnerabilityFindingModal,
    VulnerabilityReportLayout,
    SecurityDashboardTable,
    LoadingError,
  },
  mixins: [glFeatureFlagMixin(), vulnerabilityModalMixin('vulnerabilities')],
  inject: ['pipeline', 'projectId', 'projectFullPath'],
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
  data() {
    return {
      shouldShowModal: false,
    };
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

    if (this.glFeatures.standaloneFindingModal) {
      // the click on a report row will trigger the BV_SHOW_MODAL event
      this.$root.$on(BV_SHOW_MODAL, this.showModal);
    }
  },
  beforeDestroy() {
    if (this.glFeatures.standaloneFindingModal) {
      this.$root.$off(BV_SHOW_MODAL, this.showModal);
    }
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
      'reFetchVulnerabilitiesAfterDismissal',
    ]),
    ...mapActions('pipelineJobs', ['setPipelineJobsPath', 'setProjectId', 'fetchPipelineJobs']),
    ...mapActions('filters', ['lockFilter', 'setHideDismissedToggleInitialState']),
    showModal(modalId) {
      if (modalId === VULNERABILITY_MODAL_ID) {
        this.shouldShowModal = true;
      }
    },
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

      <vulnerability-finding-modal
        v-if="glFeatures.standaloneFindingModal && shouldShowModal"
        :finding-uuid="vulnerability.uuid"
        :pipeline-iid="pipeline.iid"
        :project-full-path="projectFullPath"
        @state-updated="reFetchVulnerabilitiesAfterDismissal({ vulnerability })"
        @hidden="shouldShowModal = false"
      />
      <issue-modal
        v-if="!glFeatures.standaloneFindingModal"
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
