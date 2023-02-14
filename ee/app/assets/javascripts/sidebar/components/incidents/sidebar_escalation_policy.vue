<script>
import { GlLink } from '@gitlab/ui';
import { joinPaths } from '~/lib/utils/url_utility';
import { TYPE_ISSUE } from '~/issues/constants';
import { IssuableAttributeType } from '../../constants';
import SidebarDropdownWidget from '../sidebar_dropdown_widget.vue';
import EscalationPoliciesEmptyState from './escalation_policies_empty_state.vue';
import EscalationPolicyCollapsedState from './escalation_policy_collapsed_state.vue';

export default {
  INDEX_PATH: '-/escalation_policies',
  components: {
    SidebarDropdownWidget,
    EscalationPolicyCollapsedState,
    GlLink,
    EscalationPoliciesEmptyState,
  },
  props: {
    projectPath: {
      required: true,
      type: String,
    },
    iid: {
      required: true,
      type: String,
    },
    escalationsPossible: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    policiesPath() {
      return joinPaths(gon.relative_url_root || '/', this.projectPath, this.$options.INDEX_PATH);
    },
  },
  created() {
    this.issuableType = TYPE_ISSUE;
    this.issuableAttribute = IssuableAttributeType.EscalationPolicy;
  },
};
</script>

<template>
  <sidebar-dropdown-widget
    v-if="escalationsPossible"
    :attr-workspace-path="projectPath"
    :workspace-path="projectPath"
    :iid="iid"
    :issuable-type="issuableType"
    :issuable-attribute="issuableAttribute"
  >
    <template #value-collapsed="{ currentAttribute }">
      <escalation-policy-collapsed-state :value="currentAttribute && currentAttribute.title" />
    </template>

    <template #value="{ attributeTitle }">
      <gl-link class="gl-text-gray-900! gl-font-weight-bold" :href="policiesPath">
        {{ attributeTitle }}
      </gl-link>
    </template>
  </sidebar-dropdown-widget>

  <escalation-policies-empty-state v-else />
</template>
