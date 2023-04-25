<script>
import { COVERAGE_CHECK_NAME, APPROVAL_RULE_CONFIGS } from '../constants';
import ApprovalCheckPopover from './approval_check_popover.vue';

export default {
  name: 'ApprovalCheckRulePopover',
  components: {
    ApprovalCheckPopover,
  },
  props: {
    rule: {
      type: Object,
      required: true,
    },
    codeCoverageCheckHelpPagePath: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    showCoverageCheckPopover() {
      return this.rule.name === COVERAGE_CHECK_NAME;
    },
    approvalRuleConfig() {
      return APPROVAL_RULE_CONFIGS[this.rule.name];
    },
    documentationLink() {
      /*
       * The docs for these two rules have the same url & anchor
       * We get the path from a rails view helper
       */
      if (this.showCoverageCheckPopover) {
        return this.codeCoverageCheckHelpPagePath;
      }
      return '';
    },
    popoverTriggerId() {
      return `reportInfo-${this.rule.name}`;
    },
  },
};
</script>

<template>
  <approval-check-popover
    v-if="showCoverageCheckPopover"
    :popover-id="popoverTriggerId"
    :title="approvalRuleConfig.title"
    :text="approvalRuleConfig.popoverText"
    :documentation-link="documentationLink"
    :documentation-text="approvalRuleConfig.documentationText"
  />
</template>
