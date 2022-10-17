<script>
import { GlButton, GlFormInput, GlSprintf, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { s__, n__ } from '~/locale';
import { slugifyToArray } from '../utils';
import { SCAN_EXECUTION_RULES_LABELS } from './constants';

export default {
  SCAN_EXECUTION_RULES_LABELS,
  i18n: {
    scanExecutionRuleCopy: s__(
      'ScanExecutionPolicy|%{rules} actions for the %{scopes} %{branches} %{agents} %{namespaces}',
    ),
    selectedBranchesPlaceholder: s__('ScanExecutionPolicy|Select branches'),
  },
  name: 'BaseRuleComponent',
  components: {
    GlButton,
    GlDropdown,
    GlDropdownItem,
    GlFormInput,
    GlSprintf,
  },
  props: {
    initRule: {
      type: Object,
      required: true,
    },
    ruleLabel: {
      type: String,
      required: true,
    },
    defaultSelectedRule: {
      type: String,
      required: false,
      default: SCAN_EXECUTION_RULES_LABELS.pipeline,
    },
    isBranchScope: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  data() {
    return {
      selectedRule: this.defaultSelectedRule,
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
    branchesToAdd: {
      get() {
        return (this.initRule.branches?.length || 0) === 0
          ? ''
          : this.initRule.branches?.filter((element) => element?.trim()).join(',');
      },
      set(values) {
        const branches = slugifyToArray(values, ',');
        this.$emit('changed', { ...this.initRule, branches });
      },
    },
  },
  methods: {
    isSelectedRule(key) {
      return this.selectedRule === this.$options.SCAN_EXECUTION_RULES_LABELS[key];
    },
    setSelectedRule(key) {
      this.selectedRule = this.$options.SCAN_EXECUTION_RULES_LABELS[key];
      this.$emit('select-rule', key);
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-gap-3 gl-bg-gray-10 gl-rounded-base gl-p-5 gl-relative">
    <div class="gl-min-w-7">
      <label
        for="scanners"
        class="text-uppercase gl-font-lg gl-w-6 gl-pl-2"
        data-testid="rule-component-label"
        >{{ ruleLabel }}</label
      >
    </div>

    <div class="gl-flex-grow-1">
      <div class="gl-w-full gl-display-flex gl-gap-3 gl-align-items-center gl-flex-wrap">
        <gl-sprintf :message="$options.i18n.scanExecutionRuleCopy">
          <template #scopes>
            <slot name="scopes"></slot>
          </template>

          <template #rules>
            <gl-dropdown :text="selectedRule" data-testid="rule-component-type">
              <gl-dropdown-item
                v-for="(label, key) in $options.SCAN_EXECUTION_RULES_LABELS"
                :key="key"
                is-check-item
                :is-checked="isSelectedRule(key)"
                @click="setSelectedRule(key)"
              >
                {{ label }}
              </gl-dropdown-item>
            </gl-dropdown>
          </template>

          <template #branches>
            <template v-if="isBranchScope">
              <gl-form-input
                v-model="branchesToAdd"
                class="gl-mr-3 gl-max-w-34"
                size="lg"
                :placeholder="$options.i18n.selectedBranchesPlaceholder"
                data-testid="rule-branches"
              />
              <span data-testid="rule-branches-label"> {{ branchesLabel }} </span>
            </template>
          </template>

          <template #agents>
            <slot name="agents"></slot>
          </template>

          <template #namespaces>
            <slot name="namespaces"></slot>
          </template>
        </gl-sprintf>
      </div>

      <slot name="content"></slot>
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
