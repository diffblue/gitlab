<script>
import { s__, __, sprintf } from '~/locale';
import ApprovalCheckPopover from 'ee/approvals/components/approval_check_popover.vue';
import { INVALID_RULES_DOCS_PATH } from '~/vue_merge_request_widget/constants';

export default {
  components: {
    ApprovalCheckPopover,
  },
  props: {
    rule: {
      type: Object,
      required: true,
    },
    invalidApproversRules: {
      type: Array,
      required: true,
    },
  },
  computed: {
    pendingApprovalsText() {
      if (!this.rule.approvalsRequired) {
        return __('Optional');
      }
      if (this.hasInvalidRules) {
        return __('Invalid');
      }
      return sprintf(__('%{count} of %{total}'), {
        count: this.rule.approvedBy.nodes.length,
        total: this.rule.approvalsRequired,
      });
    },
    hasInvalidRules() {
      return this.invalidApproversRules.some((invalidRule) => invalidRule.id === this.rule.id);
    },
  },
  i18n: {
    learnMore: __('Learn more.'),
    title: __('Invalid rule'),
    text: s__("mrWidget|No users match the rule's criteria."),
  },
  documentationLink: INVALID_RULES_DOCS_PATH,
};
</script>

<template>
  <span>
    <span data-testid="approvals-text">{{ pendingApprovalsText }}</span>
    <approval-check-popover
      v-if="hasInvalidRules"
      :popover-id="rule.name"
      icon-name="question-o"
      :title="$options.i18n.title"
      :text="$options.i18n.text"
      :documentation-link="$options.documentationLink"
      :documentation-text="$options.i18n.learnMore"
    />
  </span>
</template>
