<script>
import { GlButton } from '@gitlab/ui';
import { __ } from '~/locale';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';
import ApprovalsList from './approvals_list.vue';

export default {
  components: {
    GlButton,
    UserAvatarList,
    ApprovalsList,
  },
  props: {
    suggestedApprovers: {
      type: Array,
      required: true,
    },
    approvalRules: {
      type: Array,
      required: true,
    },
    value: {
      type: Boolean,
      required: false,
      default: true,
    },
    isLoadingRules: {
      type: Boolean,
      required: false,
      default: false,
    },
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
  },
  computed: {
    isCollapsed() {
      return !this.value;
    },
    ariaLabel() {
      return this.isCollapsed ? __('Expand approvers') : __('Collapse approvers');
    },
    angleIcon() {
      return this.isCollapsed ? 'chevron-right' : 'chevron-down';
    },
    suggestedApproversTrimmed() {
      return this.suggestedApprovers.slice(0, Math.min(5, this.suggestedApprovers.length));
    },
    shouldShowLoadingSpinner() {
      return !this.isCollapsed && this.isLoadingRules;
    },
  },
  methods: {
    toggle() {
      this.$emit('input', !this.value);
    },
  },
};
</script>

<template>
  <div class="mr-widget-extension">
    <div class="d-flex align-items-center pl-3 gl-py-3">
      <gl-button
        class="gl-mr-3"
        size="small"
        :aria-label="ariaLabel"
        :loading="shouldShowLoadingSpinner"
        :icon="angleIcon"
        category="tertiary"
        @click="toggle"
      />
      <template v-if="isCollapsed">
        <user-avatar-list
          :items="suggestedApproversTrimmed"
          :img-size="24"
          :breakpoint="0"
          empty-text=""
        />
        <gl-button
          data-testid="approvers-expand-button"
          category="tertiary"
          variant="confirm"
          size="small"
          @click="toggle"
          >{{ __('View eligible approvers') }}</gl-button
        >
      </template>
      <template v-else>
        <gl-button
          data-testid="approvers-collapse-button"
          category="tertiary"
          variant="confirm"
          size="small"
          @click="toggle"
          >{{ __('Collapse') }}</gl-button
        >
      </template>
    </div>
    <div v-if="!isCollapsed && approvalRules.length" class="border-top">
      <approvals-list
        :approval-rules="approvalRules"
        :invalid-approvers-rules="invalidApproversRules"
        :security-approvals-help-page-path="securityApprovalsHelpPagePath"
        :eligible-approvers-docs-path="eligibleApproversDocsPath"
      />
    </div>
  </div>
</template>
