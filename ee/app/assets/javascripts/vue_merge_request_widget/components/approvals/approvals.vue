<script>
import Approvals from '~/vue_merge_request_widget/components/approvals/approvals.vue';
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
      modalId: 'approvals-auth',
      collapsed: true,
    };
  },
  computed: {
    isBasic() {
      return this.mr.approvalsWidgetType === 'base';
    },
    approvedBy() {
      return this.approvals.approvedBy?.nodes || [];
    },
    approvalsRequired() {
      return (!this.isBasic && this.approvals.approvalsRequired) || 0;
    },
    isOptional() {
      return !this.approvedBy.length && !this.approvalsRequired;
    },
    hasFooter() {
      return Boolean(this.approvals);
    },
    requirePasswordToApprove() {
      return !this.isBasic && this.mr.requirePasswordToApprove;
    },
  },
  methods: {
    toggleCollapsed() {
      this.collapsed = !this.collapsed;
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
    :collapsed="collapsed"
    @toggle="toggleCollapsed"
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
    <template v-if="!isBasic && !collapsed" #footer>
      <approvals-footer
        v-if="hasFooter"
        :security-approvals-help-page-path="mr.securityApprovalsHelpPagePath"
        :eligible-approvers-docs-path="mr.eligibleApproversDocsPath"
        :project-path="mr.targetProjectFullPath"
        :iid="`${mr.iid}`"
      />
    </template>
  </approvals>
</template>
