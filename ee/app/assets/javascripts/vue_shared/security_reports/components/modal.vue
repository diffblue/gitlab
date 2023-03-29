<script>
import { GlModal, GlAlert, GlLoadingIcon } from '@gitlab/ui';
import DismissalCommentBoxToggle from 'ee/vue_shared/security_reports/components/dismissal_comment_box_toggle.vue';
import DismissalCommentModalFooter from 'ee/vue_shared/security_reports/components/dismissal_comment_modal_footer.vue';
import DismissalNote from 'ee/vue_shared/security_reports/components/dismissal_note.vue';
import IssueNote from 'ee/vue_shared/security_reports/components/issue_note.vue';
import MergeRequestNote from 'ee/vue_shared/security_reports/components/merge_request_note.vue';
import ModalFooter from 'ee/vue_shared/security_reports/components/modal_footer.vue';
import SolutionCard from 'ee/vue_shared/security_reports/components/solution_card_vuex.vue';
import VulnerabilityDetails from 'ee/vue_shared/security_reports/components/vulnerability_details.vue';
import { __ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import {
  getCreatedIssueForVulnerability,
  getDismissalTransitionForVulnerability,
} from 'ee/vue_shared/security_reports/components/helpers';
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
    GlLoadingIcon,
    ModalFooter,
    SolutionCard,
    VulnerabilityDetails,
  },
  mixins: [glFeatureFlagMixin()],
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
    isLoadingAdditionalInfo: {
      type: Boolean,
      required: false,
      default: false,
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
      return Boolean(!this.isResolved && !this.hasIssue && this.canCreateIssue);
    },
    canCreateMergeRequestForThisVulnerability() {
      return Boolean(!this.isResolved && !this.mergeRequestData && this.remediation);
    },
    canDismissThisVulnerability() {
      return Boolean(!this.isResolved && this.canDismissVulnerability);
    },
    canDownloadPatchForThisVulnerability() {
      return Boolean(
        !this.isResolved && this.remediation?.diff?.length > 0 && !this.mergeRequestData,
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
    issueData() {
      return this.glFeatures.deprecateVulnerabilitiesFeedback
        ? getCreatedIssueForVulnerability(this.vulnerability)
        : this.vulnerability?.issue_feedback;
    },
    hasIssue() {
      // Issues can be deleted. After an issue is deleted, issue_feedback will still be an object, but it won't have
      // an issue_iid. issue_links however will remove the object from the array. Once we enable and remove the
      // deprecate_vulnerabilities_feedback feature flag, it's no longer necessary to check for issue_iid, and this
      // computed property can be deleted in favor of checking whether issueData is truthy instead.
      return Boolean(this.issueData?.issue_iid);
    },
    mergeRequestData() {
      return this.glFeatures.deprecateVulnerabilitiesFeedback
        ? this.vulnerability?.merge_request_links?.at(-1)
        : this.vulnerability?.merge_request_feedback;
    },
    dismissalData() {
      if (this.glFeatures.deprecateVulnerabilitiesFeedback) {
        const transition = getDismissalTransitionForVulnerability(this.vulnerability);

        if (!transition) {
          return null;
        }

        const commentDetails = transition.comment
          ? { comment: transition.comment, comment_author: transition.author }
          : null;
        // Return the dismissal data in the format the dismissal note expects.
        return {
          author: transition.author,
          created_at: transition.created_at,
          comment_details: commentDetails,
        };
      }

      return this.vulnerability?.dismissalFeedback || this.vulnerability?.dismissal_feedback;
    },
    isEditingDismissalComment() {
      return this.dismissalData && this.modal.isCommentingOnDismissal;
    },
    dismissalDataOrCurrentUser() {
      // If a user is dismissing and adding a comment at the same time, there is no dismissal data, so we create a fake
      // one with the author as the current user so that the UI shows the dismissal note correctly.
      return (
        this.dismissalData || {
          author: {
            id: gon.current_user_id,
            name: gon.current_user_fullname,
            username: gon.current_username,
            avatar_url: gon.current_user_avatar_url,
          },
        }
      );
    },
    dismissalComment() {
      return this.dismissalData?.comment_details?.comment;
    },
    showFeedbackNotes() {
      return Boolean(this.issueData?.issue_url || this.mergeRequestData?.merge_request_path);
    },
    showDismissalCard() {
      return Boolean(this.dismissalData) || this.modal.isCommentingOnDismissal;
    },
    showDismissalCommentActions() {
      return !this.dismissalData?.comment_details || !this.isEditingDismissalComment;
    },
    showDismissalCommentTextbox() {
      return !this.dismissalData?.comment_details || this.isEditingDismissalComment;
    },
  },
  methods: {
    handleDismissalCommentSubmission() {
      if (this.dismissalData) {
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
    @hidden="$emit('hidden')"
  >
    <slot>
      <vulnerability-details :vulnerability="vulnerability" class="js-vulnerability-details" />

      <solution-card
        :solution="solution"
        :remediation="remediation"
        :has-mr="Boolean(mergeRequestData)"
        :has-download="canDownloadPatchForThisVulnerability"
      />

      <gl-loading-icon v-if="isLoadingAdditionalInfo" />

      <div v-if="showFeedbackNotes" class="card my-4">
        <issue-note v-if="hasIssue" :feedback="issueData" :project="project" class="card-body" />
        <merge-request-note
          v-if="mergeRequestData"
          :feedback="mergeRequestData"
          :project="project"
          class="card-body"
        />
      </div>

      <div v-if="showDismissalCard" class="card card-body my-4">
        <dismissal-note
          :feedback="dismissalDataOrCurrentUser"
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
          :dismissal-comment="dismissalComment"
          :is-active="modal.isCommentingOnDismissal"
          :error-message="dismissalCommentErrorMessage"
          @openDismissalCommentBox="$emit('openDismissalCommentBox')"
          @submit="handleDismissalCommentSubmission"
          @clearError="clearDismissalError"
        />
      </div>

      <gl-alert v-if="modal.error" variant="danger" :dismissible="false">
        {{ modal.error }}
      </gl-alert>
    </slot>
    <template #modal-footer>
      <dismissal-comment-modal-footer
        v-if="modal.isCommentingOnDismissal"
        :is-dismissed="Boolean(dismissalData)"
        :is-editing-existing-feedback="isEditingDismissalComment"
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
        :is-dismissed="Boolean(dismissalData)"
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
