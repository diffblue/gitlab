<script>
import ApprovalsList from './approvals_list.vue';

export default {
  components: {
    ApprovalsList,
  },
  props: {
    securityApprovalsHelpPagePath: {
      type: String,
      required: false,
      default: '',
    },
    eligibleApproversDocsPath: {
      type: String,
      required: false,
      default: '',
    },
    invalidApproversRules: {
      type: Array,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
    iid: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div
    class="mr-widget-extension gl-rounded-bottom-left-base gl-rounded-bottom-right-base gl-border-t-0"
    data-testid="approvals-footer"
  >
    <approvals-list
      :invalid-approvers-rules="invalidApproversRules"
      :security-approvals-help-page-path="securityApprovalsHelpPagePath"
      :eligible-approvers-docs-path="eligibleApproversDocsPath"
      :project-path="projectPath"
      :iid="iid"
    />
  </div>
</template>
