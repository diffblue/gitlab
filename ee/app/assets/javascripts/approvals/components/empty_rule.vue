<script>
import { GlButton } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
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
    <td colspan="2" :data-label="__('Approvers')">
      <empty-rule-name :eligible-approvers-docs-path="eligibleApproversDocsPath" />
    </td>
    <td v-if="showProtectedBranch" :data-label="__('Target branch')">
      <rule-branches :rule="rule" />
    </td>
    <td class="js-approvals-required gl-text-right" :data-label="__('Approvals required')">
      <rule-input :rule="rule" :is-mr-edit="isMrEdit" />
    </td>
    <td class="gl-md-pl-0! gl-md-pr-0!">
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
