<script>
import { GlBadge, GlButton, GlCollapse, GlIcon, GlModal } from '@gitlab/ui';
import { n__, s__, __, sprintf } from '~/locale';
import { DEPLOYER_RULE_KEY, APPROVER_RULE_KEY } from './constants';

export default {
  components: { GlBadge, GlButton, GlCollapse, GlIcon, GlModal },
  props: {
    environments: {
      required: true,
      type: Array,
    },
  },
  data() {
    return { expanded: {}, environmentToUnprotect: null };
  },
  computed: {
    confirmUnprotectText() {
      return sprintf(
        s__(
          'ProtectedEnvironment|Users with at least the Developer role can write to unprotected environments. Are you sure you want to unprotect %{environment_name}?',
        ),
        { environment_name: this.environmentToUnprotect?.name },
      );
    },
    isUnprotectModalVisible() {
      return Boolean(this.environmentToUnprotect);
    },
  },
  methods: {
    isLast(index) {
      return index === this.environments.length - 1;
    },
    isFirst(index) {
      return index === 0;
    },
    toggleCollapse({ name }) {
      this.$set(this.expanded, name, !this.expanded[name]);
    },
    isExpanded({ name }) {
      return this.expanded[name];
    },
    icon(environment) {
      return this.isExpanded(environment) ? 'chevron-up' : 'chevron-down';
    },
    approvalRulesText({ [APPROVER_RULE_KEY]: approvalRules }) {
      return n__(
        'ProtectedEnvironments|%d Approval Rule',
        'ProtectedEnvironments|%d Approval Rules',
        approvalRules.length,
      );
    },
    deploymentRulesText({ [DEPLOYER_RULE_KEY]: deploymentRules }) {
      return n__(
        'ProtectedEnvironments|%d Deployment Rule',
        'ProtectedEnvironments|%d Deployment Rules',
        deploymentRules.length,
      );
    },
    confirmUnprotect(environment) {
      this.environmentToUnprotect = environment;
    },
    unprotect() {
      this.$emit('unprotect', this.environmentToUnprotect);
      this.environmentToUnprotect = null;
    },
  },
  modalOptions: {
    modalId: 'confirm-unprotect-environment',
    size: 'sm',
    actionPrimary: {
      text: __('OK'),
      attributes: { variant: 'danger' },
    },
    actionSecondary: {
      text: __('Cancel'),
    },
  },
};
</script>
<template>
  <div>
    <gl-modal
      :visible="isUnprotectModalVisible"
      v-bind="$options.modalOptions"
      @primary="unprotect"
    >
      {{ confirmUnprotectText }}
    </gl-modal>
    <div
      v-for="(environment, index) in environments"
      :key="environment.name"
      :class="{ 'gl-border-b': !isLast(index), 'gl-mt-5': !isFirst(index) }"
    >
      <gl-button
        block
        category="tertiary"
        variant="confirm"
        button-text-classes="gl-display-flex gl-w-full gl-align-items-baseline"
        :aria-label="environment.name"
        @click="toggleCollapse(environment)"
      >
        <span class="gl-font-weight-bold gl-py-2">{{ environment.name }}</span>
        <gl-badge v-if="!isExpanded(environment)" class="gl-ml-auto">
          {{ deploymentRulesText(environment) }}
        </gl-badge>
        <gl-badge v-if="!isExpanded(environment)" class="gl-ml-3">
          {{ approvalRulesText(environment) }}
        </gl-badge>
        <gl-icon
          :name="icon(environment)"
          :size="14"
          :class="{ 'gl-ml-3': !isExpanded(environment), 'gl-ml-auto': isExpanded(environment) }"
        />
      </gl-button>
      <gl-collapse
        :visible="isExpanded(environment)"
        class="gl-display-flex gl-flex-direction-column gl-mb-5"
      >
        <slot :environment="environment"></slot>
        <gl-button
          category="secondary"
          variant="danger"
          class="gl-mt-5 gl-align-self-end"
          @click="confirmUnprotect(environment)"
        >
          {{ s__('ProtectedEnvironments|Unprotect') }}
        </gl-button>
      </gl-collapse>
    </div>
  </div>
</template>
