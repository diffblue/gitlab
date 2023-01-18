<script>
import { createAlert } from '~/flash';
import { BV_HIDE_MODAL } from '~/lib/utils/constants';
import Approvals from '~/vue_merge_request_widget/components/approvals/approvals.vue';
import { FETCH_ERROR } from '~/vue_merge_request_widget/components/approvals/messages';
import approvalsMixin from '~/vue_merge_request_widget/mixins/approvals';
import ApprovalsAuth from './approvals_auth.vue';
import ApprovalsFooter from './approvals_footer.vue';

export default {
  name: 'MRWidgetMultipleRuleApprovals',
  components: {
    Approvals,
    ApprovalsAuth,
    ApprovalsFooter,
  },
  mixins: [approvalsMixin],
  props: {
    mr: {
      type: Object,
      required: true,
    },
    service: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isLoadingRules: false,
      isExpanded: false,
      modalId: 'approvals-auth',
    };
  },
  computed: {
    isBasic() {
      return this.mr.approvalsWidgetType === 'base';
    },
    approvals() {
      return this.mr.approvals || {};
    },
    approvedBy() {
      return this.approvals.approved_by ? this.approvals.approved_by.map((x) => x.user) : [];
    },
    approvalsRequired() {
      return (!this.isBasic && this.approvals.approvals_required) || 0;
    },
    isOptional() {
      return !this.approvedBy.length && !this.approvalsRequired;
    },
    hasFooter() {
      return Boolean(this.mr.approvals);
    },
    requirePasswordToApprove() {
      return !this.isBasic && this.approvals.require_password_to_approve;
    },
    invalidRules() {
      return this.approvals.invalid_approvers_rules || [];
    },
  },
  watch: {
    isExpanded(val) {
      if (val) {
        this.refreshAll();
      }
    },
  },
  methods: {
    refreshAll() {
      if (this.isBasic) return Promise.resolve();

      return Promise.all([this.refreshRules(), this.refreshApprovals()]).catch(() =>
        this.alerts.push(
          createAlert({
            message: FETCH_ERROR,
          }),
        ),
      );
    },
    refreshRules() {
      if (this.isBasic) return Promise.resolve();

      this.$root.$emit(BV_HIDE_MODAL, this.modalId);

      this.isLoadingRules = true;

      return this.service.fetchApprovalSettings().then((settings) => {
        this.mr.setApprovalRules(settings);
        this.isLoadingRules = false;
      });
    },
  },
};
</script>
<template>
  <approvals
    :mr="mr"
    :service="service"
    :is-optional-default="isOptional"
    :require-password-to-approve="requirePasswordToApprove"
    :modal-id="modalId"
    @updated="refreshRules"
  >
    <template v-if="!isBasic" #default="{ isApproving, approveWithAuth, hasApprovalAuthError }">
      <approvals-auth
        :is-approving="isApproving"
        :has-error="hasApprovalAuthError"
        :modal-id="modalId"
        @approve="approveWithAuth"
        @hide="clearError"
      />
    </template>
    <template v-if="!isBasic" #footer>
      <approvals-footer
        v-if="hasFooter"
        v-model="isExpanded"
        :suggested-approvers="approvals.suggested_approvers"
        :invalid-approvers-rules="invalidRules"
        :approval-rules="mr.approvalRules"
        :is-loading-rules="isLoadingRules"
        :security-approvals-help-page-path="mr.securityApprovalsHelpPagePath"
        :eligible-approvers-docs-path="mr.eligibleApproversDocsPath"
      />
    </template>
  </approvals>
</template>
