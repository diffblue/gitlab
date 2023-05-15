<script>
import { GlButton, GlIcon } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  i18n: {
    details: __('View details'),
    allProtectedBranches: __('All protected branches'),
  },
  components: {
    GlButton,
    GlIcon,
  },
  props: {
    policy: {
      type: Object,
      required: true,
    },
  },
  computed: {
    policyAction() {
      return this.policy.actions?.find(({ type }) => type === 'require_approval') || {};
    },
    branches() {
      const allRulesBranches = this.policy.rules?.flatMap(({ branches = [] }) => branches);
      return allRulesBranches.length
        ? allRulesBranches.join(', ')
        : this.$options.i18n.allProtectedBranches;
    },
    approvalsRequired() {
      return this.policyAction.approvals_required;
    },
    iconName() {
      return this.policy.isSelected ? 'chevron-up' : 'chevron-down';
    },
  },
  methods: {
    updateSelected() {
      this.$emit('toggle');
    },
  },
};
</script>

<template>
  <tr>
    <td>
      {{ policy.name }}
    </td>
    <td>
      {{ branches }}
    </td>
    <td class="gl-text-center">
      {{ approvalsRequired }}
    </td>
    <td>
      <gl-button category="tertiary" size="small" variant="confirm" @click="updateSelected()">
        {{ $options.i18n.details }}
        <gl-icon :name="iconName" />
      </gl-button>
    </td>
  </tr>
</template>
