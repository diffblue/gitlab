<script>
import { GlModal, GlAlert } from '@gitlab/ui';
import DismissalCommentBoxToggle from 'ee/vue_shared/security_reports/components/dismissal_comment_box_toggle.vue';
import DismissalCommentModalFooter from 'ee/vue_shared/security_reports/components/dismissal_comment_modal_footer.vue';
import DismissalNote from 'ee/vue_shared/security_reports/components/dismissal_note.vue';
import IssueNote from 'ee/vue_shared/security_reports/components/issue_note.vue';
import MergeRequestNote from 'ee/vue_shared/security_reports/components/merge_request_note.vue';
import ModalFooter from 'ee/vue_shared/security_reports/components/modal_footer.vue';
import SolutionCard from 'ee/vue_shared/security_reports/components/solution_card_vuex.vue';
import VulnerabilityDetails from 'ee/vue_shared/security_reports/components/vulnerability_details.vue';
import { __ } from '~/locale';
import { VULNERABILITY_MODAL_ID } from './constants';

export default {
  VULNERABILITY_MODAL_ID,
  components: {
    DismissalNote,
    DismissalCommentBoxToggle,
    DismissalCommentModalFooter,
    IssueNote,
    MergeRequestNote,
    GlAlert,
    GlModal,
    ModalFooter,
    SolutionCard,
    VulnerabilityDetails,
  },
  props: {
    modal: {
      type: Object,
      required: true,
    },
    canCreateIssue: {
      type: Boolean,
      required: false,
      default: false,
    },
    canCreateMergeRequest: {
      type: Boolean,
      required: false,
      default: false,
    },
    canDismissVulnerability: {
      type: Boolean,
      required: false,
      default: false,
    },
    isCreatingIssue: {
      type: Boolean,
      required: true,
    },
    isDismissingVulnerability: {
      type: Boolean,
      required: true,
    },
    isCreatingMergeRequest: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      localDismissalComment: '',
      dismissalCommentErrorMessage: '',
    };
  },
  computed: {
    canCreateIssueForThisVulnerability() {
      return Boolean(!this.isResolved && !this.vulnerability.hasIssue && this.canCreateIssue);
    },
    canCreateMergeRequestForThisVulnerability() {
      return Boolean(!this.isResolved && !this.vulnerability.hasMergeRequest && this.remediation);
    },
    canDismissThisVulnerability() {
      return Boolean(!this.isResolved && this.canDismissVulnerability);
    },
    canDownloadPatchForThisVulnerability() {
      return Boolean(
        !this.isResolved &&
          this.remediation?.diff?.length > 0 &&
          !this.vulnerability.hasMergeRequest &&
          this.remediation,
      );
    },
    isResolved() {
      return Boolean(this.modal.isResolved);
    },
    project() {
      return this.modal.project;
    },
    solution() {
      return this.vulnerability?.solution;
    },
    remediation() {
      return this.vulnerability?.remediations?.[0];
    },
    vulnerability() {
      return this.modal.vulnerability;
    },
    issueFeedback() {
      return this.vulnerability?.issue_feedback;
    },
    canReadIssueFeedback() {
      return this.issueFeedback?.issue_url;
    },
    mergeRequestFeedback() {
      return this.vulnerability?.merge_request_feedback;
    },
    canReadMergeRequestFeedback() {
      return this.mergeRequestFeedback?.merge_request_path;
    },
    dismissalFeedback() {
      // grouped security reports are populating `dismissalFeedback` and the dashboards `dismissal_feedback`
      // https://gitlab.com/gitlab-org/gitlab/issues/207489 aims to use the same property in all cases
      return this.vulnerability?.dismissalFeedback || this.vulnerability?.dismissal_feedback;
    },
    isEditingExistingFeedback() {
      return this.dismissalFeedback && this.modal.isCommentingOnDismissal;
    },
    dismissalFeedbackObject() {
      if (this.dismissalFeedback) {
        return this.dismissalFeedback;
      }

      // If we don't have access to the feedback object, we can preempt the data with properties taken from the `gon` variable

      const {
        current_user_avatar_url: avatarUrl,
        current_user_fullname: name,
        current_user_id: id,
        current_username: username,
      } = gon;

      return {
        author: {
          id,
          name,
          username,
          state: 'active',
          avatar_url: avatarUrl,
        },
      };
    },
    dismissalFeedbackComment() {
      return this.dismissalFeedback?.comment_details?.comment;
    },
    showFeedbackNotes() {
      return (
        (this.canReadIssueFeedback || this.canReadMergeRequestFeedback) &&
        (this.issueFeedback || this.mergeRequestFeedback)
      );
    },
    showDismissalCard() {
      return this.dismissalFeedback || this.modal.isCommentingOnDismissal;
    },
    showDismissalCommentActions() {
      return !this.dismissalFeedback?.comment_details || !this.isEditingExistingFeedback;
    },
    showDismissalCommentTextbox() {
      return !this.dismissalFeedback?.comment_details || this.isEditingExistingFeedback;
    },
  },
  methods: {
    handleDismissalCommentSubmission() {
      if (this.dismissalFeedback) {
        this.addDismissalComment();
      } else {
        this.addCommentAndDismiss();
      }
    },
    addCommentAndDismiss() {
      if (this.localDismissalComment.length) {
        this.$emit('dismissVulnerability', this.localDismissalComment);
      } else {
        this.addDismissalError();
      }
    },
    addDismissalComment() {
      if (this.localDismissalComment.length) {
        this.$emit('addDismissalComment', this.localDismissalComment);
      } else {
        this.addDismissalError();
      }
    },
    addDismissalError() {
      this.dismissalCommentErrorMessage = __('Please add a comment in the text area above');
    },
    clearDismissalError() {
      this.dismissalCommentErrorMessage = '';
    },
    close() {
      this.$refs.modal.close();
    },
  },
};
</script>
<template>
  <gl-modal
    ref="modal"
    :modal-id="$options.VULNERABILITY_MODAL_ID"
    :title="modal.title"
    size="lg"
    data-qa-selector="vulnerability_modal_content"
    class="modal-security-report-dast"
    v-bind="$attrs"
  >
    <slot>
      <vulnerability-details :vulnerability="vulnerability" class="js-vulnerability-details" />

      <solution-card
        :solution="solution"
        :remediation="remediation"
        :has-mr="vulnerability.hasMergeRequest"
        :has-download="canDownloadPatchForThisVulnerability"
      />

      <div v-if="showFeedbackNotes" class="card my-4">
        <issue-note
          v-if="issueFeedback"
          :feedback="issueFeedback"
          :project="project"
          class="card-body"
        />
        <merge-request-note
          v-if="mergeRequestFeedback"
          :feedback="mergeRequestFeedback"
          :project="project"
          class="card-body"
        />
      </div>

      <div v-if="showDismissalCard" class="card card-body my-4">
        <dismissal-note
          :feedback="dismissalFeedbackObject"
          :is-commenting-on-dismissal="modal.isCommentingOnDismissal"
          :is-showing-delete-buttons="modal.isShowingDeleteButtons"
          :project="project"
          :show-dismissal-comment-actions="showDismissalCommentActions"
          @editVulnerabilityDismissalComment="$emit('editVulnerabilityDismissalComment')"
          @showDismissalDeleteButtons="$emit('showDismissalDeleteButtons')"
          @hideDismissalDeleteButtons="$emit('hideDismissalDeleteButtons')"
          @deleteDismissalComment="$emit('deleteDismissalComment')"
        />
        <dismissal-comment-box-toggle
          v-if="showDismissalCommentTextbox"
          v-model="localDismissalComment"
          :dismissal-comment="dismissalFeedbackComment"
          :is-active="modal.isCommentingOnDismissal"
          :error-message="dismissalCommentErrorMessage"
          @openDismissalCommentBox="$emit('openDismissalCommentBox')"
          @submit="handleDismissalCommentSubmission"
          @clearError="clearDismissalError"
        />
      </div>

      <gl-alert v-if="modal.error" variant="danger" :dismissible="false">{{
        modal.error
      }}</gl-alert>
    </slot>
    <template #modal-footer>
      <dismissal-comment-modal-footer
        v-if="modal.isCommentingOnDismissal"
        :is-dismissed="vulnerability.isDismissed"
        :is-editing-existing-feedback="isEditingExistingFeedback"
        :is-dismissing-vulnerability="isDismissingVulnerability"
        @addCommentAndDismiss="addCommentAndDismiss"
        @addDismissalComment="addDismissalComment"
        @cancel="$emit('closeDismissalCommentBox')"
      />
      <modal-footer
        v-else
        ref="footer"
        :modal="modal"
        :vulnerability="vulnerability"
        :disabled="modal.isShowingDeleteButtons"
        :can-create-issue="canCreateIssueForThisVulnerability"
        :can-create-merge-request="canCreateMergeRequestForThisVulnerability"
        :can-download-patch="canDownloadPatchForThisVulnerability"
        :can-dismiss-vulnerability="canDismissThisVulnerability"
        :is-dismissed="vulnerability.isDismissed"
        :is-creating-issue="isCreatingIssue"
        :is-dismissing-vulnerability="isDismissingVulnerability"
        :is-creating-merge-request="isCreatingMergeRequest"
        @createMergeRequest="$emit('createMergeRequest')"
        @createNewIssue="$emit('createNewIssue')"
        @dismissVulnerability="$emit('dismissVulnerability')"
        @openDismissalCommentBox="$emit('openDismissalCommentBox')"
        @revertDismissVulnerability="$emit('revertDismissVulnerability')"
        @downloadPatch="$emit('downloadPatch')"
        @cancel="close"
      />
    </template>
  </gl-modal>
</template>
