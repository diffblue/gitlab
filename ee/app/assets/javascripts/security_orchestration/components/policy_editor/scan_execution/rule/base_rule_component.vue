<script>
import { GlButton, GlSprintf, GlCollapsibleListbox } from '@gitlab/ui';
import { s__, n__ } from '~/locale';
import {
  ALL_PROTECTED_BRANCHES,
  SPECIFIC_BRANCHES,
} from 'ee/security_orchestration/components/policy_editor/constants';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import { SCAN_EXECUTION_RULES_LABELS, SCAN_EXECUTION_RULES_PIPELINE_KEY } from '../constants';
import BranchExceptionSelector from '../../branch_exception_selector.vue';
import BranchTypeSelector from './branch_type_selector.vue';

export default {
  SCAN_EXECUTION_RULES_LABELS,
  i18n: {
    pipelineRule: s__(
      'ScanExecutionPolicy|%{rules} every time a pipeline runs for %{scopes} %{branches} %{branchExceptions} %{agents} %{namespaces}',
    ),
    scheduleRule: s__(
      'ScanExecutionPolicy|%{rules} actions for %{scopes} %{branches} %{branchExceptions} %{agents} %{namespaces} %{period}',
    ),
    selectedBranchesPlaceholder: s__('ScanExecutionPolicy|Select branches'),
  },
  name: 'BaseRuleComponent',
  components: {
    BranchExceptionSelector,
    BranchTypeSelector,
    GlButton,
    GlCollapsibleListbox,
    GlSprintf,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: ['namespaceType'],
  props: {
    initRule: {
      type: Object,
      required: true,
    },
    defaultSelectedRule: {
      type: String,
      required: false,
      default: SCAN_EXECUTION_RULES_PIPELINE_KEY,
    },
    isBranchScope: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  data() {
    let selectedBranchType = ALL_PROTECTED_BRANCHES.value;

    if (this.initRule.branch_type) {
      selectedBranchType = this.initRule.branch_type;
    }

    if (this.initRule.branches) {
      selectedBranchType = SPECIFIC_BRANCHES.value;
    }

    return {
      selectedRule: this.defaultSelectedRule[this.selectedKey],
      selectedKey: this.defaultSelectedRule,
      selectedBranchType,
    };
  },
  computed: {
    branchesLabel() {
      if (!this.initRule.branches) {
        return '';
      }

      return this.initRule.branches.some((branch) => branch.includes('*'))
        ? s__('SecurityOrchestration|branches')
        : n__('branch', 'branches', this.initRule.branches.length);
    },
    branchExceptions() {
      return this.initRule.branch_exceptions;
    },
    rulesListBoxItems() {
      return Object.entries(this.$options.SCAN_EXECUTION_RULES_LABELS).map(([value, text]) => ({
        value,
        text,
      }));
    },
    branchesToAdd() {
      return (this.initRule.branches?.length || 0) === 0
        ? ''
        : this.initRule.branches?.filter((element) => element?.trim()).join(',');
    },
    message() {
      return this.initRule.type === SCAN_EXECUTION_RULES_PIPELINE_KEY
        ? this.$options.i18n.pipelineRule
        : this.$options.i18n.scheduleRule;
    },
    isProject() {
      return this.namespaceType === NAMESPACE_TYPES.PROJECT;
    },
  },
  methods: {
    setSelectedRule(key) {
      this.selectedRule = this.$options.SCAN_EXECUTION_RULES_LABELS[key];
      this.selectedKey = key;
      this.$emit('select-rule', key);
    },
    handleBranchesToAddChange(branches) {
      /**
       * Either branch of branch_type property
       * is simultaneously allowed on rule object
       * Based on value we remove one and
       * set another and vice versa
       */
      const updatedRule = { ...this.initRule, branches };
      delete updatedRule.branch_type;

      this.$emit('changed', updatedRule);
    },
    handleBranchTypeSelect(branchType) {
      this.selectedBranchType = branchType;

      if (branchType === SPECIFIC_BRANCHES.value) {
        /**
         * Pipeline rule and Schedule rule have different default values
         * Pipeline rule supports wildcard for branches
         */
        const branches = this.initRule.type === SCAN_EXECUTION_RULES_PIPELINE_KEY ? ['*'] : [];

        this.handleBranchesToAddChange(branches);

        return;
      }

      /**
       * Either branch of branch_type property
       * is simultaneously allowed on rule object
       * Based on value we remove one and
       * set another and vice versa
       */
      const updatedRule = { ...this.initRule, branch_type: branchType };
      delete updatedRule.branches;

      this.$emit('changed', updatedRule);
    },
    setBranchException(value) {
      this.$emit('changed', { ...this.initRule, ...value });
    },
  },
};
</script>

<template>
  <div
    class="security-policies-bg-gray-10 gl-display-flex gl-gap-3 gl-rounded-base gl-p-5 gl-relative"
  >
    <div class="gl-flex-grow-1">
      <div class="gl-w-full gl-display-flex gl-gap-3 gl-align-items-center gl-flex-wrap">
        <gl-sprintf :message="message">
          <template #period>
            <slot name="period"></slot>
          </template>

          <template #scopes>
            <slot name="scopes"></slot>
          </template>

          <template #rules>
            <gl-collapsible-listbox
              data-testid="rule-component-type"
              :items="rulesListBoxItems"
              :selected="selectedKey"
              :toggle-text="selectedRule"
              @select="setSelectedRule"
            />
          </template>

          <template #branches>
            <template v-if="isBranchScope">
              <branch-type-selector
                :branches-to-add="branchesToAdd"
                :selected-branch-type="selectedBranchType"
                @input="handleBranchesToAddChange"
                @set-branch-type="handleBranchTypeSelect"
              />
              <span data-testid="rule-branches-label"> {{ branchesLabel }} </span>
            </template>
          </template>

          <template #branchExceptions>
            <branch-exception-selector
              v-if="isProject && glFeatures.securityPoliciesBranchExceptions"
              :selected-exceptions="branchExceptions"
              @select="setBranchException"
            />
          </template>

          <template #agents>
            <slot name="agents"></slot>
          </template>

          <template #namespaces>
            <slot name="namespaces"></slot>
          </template>
        </gl-sprintf>
      </div>
    </div>

    <div class="gl-min-w-7 gl-ml-4">
      <gl-button
        icon="remove"
        category="tertiary"
        :aria-label="__('Remove')"
        data-testid="remove-rule"
        @click="$emit('remove')"
      />
    </div>
  </div>
</template>
