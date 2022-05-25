<script>
import { GlButton } from '@gitlab/ui';
import { mapActions } from 'vuex';
import EmptyRuleName from './empty_rule_name.vue';
import RuleInput from './mr_edit/rule_input.vue';
import RuleBranches from './rule_branches.vue';

export default {
  components: {
    RuleInput,
    EmptyRuleName,
    RuleBranches,
    GlButton,
  },
  props: {
    rule: {
      type: Object,
      required: true,
    },
    allowMultiRule: {
      type: Boolean,
      required: true,
    },
    eligibleApproversDocsPath: {
      type: String,
      required: false,
      default: '',
    },
    isMrEdit: {
      type: Boolean,
      default: true,
      required: false,
    },
    canEdit: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    showProtectedBranch() {
      return !this.isMrEdit && this.allowMultiRule;
    },
  },
  methods: {
    ...mapActions({ openCreateModal: 'createModal/open' }),
  },
};
</script>

<template>
  <tr>
    <td colspan="2">
      <empty-rule-name :eligible-approvers-docs-path="eligibleApproversDocsPath" />
    </td>
    <td v-if="showProtectedBranch">
      <rule-branches :rule="rule" />
    </td>
    <td class="js-approvals-required">
      <rule-input :rule="rule" :is-mr-edit="isMrEdit" />
    </td>
    <td>
      <gl-button
        v-if="!allowMultiRule && canEdit"
        category="secondary"
        variant="confirm"
        data-qa-selector="add_approvers_button"
        @click="openCreateModal(null)"
      >
        {{ __('Add approval rule') }}
      </gl-button>
    </td>
  </tr>
</template>
