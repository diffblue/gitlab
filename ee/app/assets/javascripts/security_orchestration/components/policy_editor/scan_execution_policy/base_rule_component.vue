<script>
import { GlButton, GlFormInput, GlSprintf, GlCollapsibleListbox } from '@gitlab/ui';
import { s__, n__ } from '~/locale';
import { slugifyToArray } from '../utils';
import { SCAN_EXECUTION_RULES_LABELS, SCAN_EXECUTION_RULES_PIPELINE_KEY } from './constants';

export default {
  SCAN_EXECUTION_RULES_LABELS,
  i18n: {
    pipelineRule: s__(
      'ScanExecutionPolicy|%{rules} every time a pipeline runs for %{scopes} %{branches} %{agents} %{namespaces}',
    ),
    scheduleRule: s__(
      'ScanExecutionPolicy|%{rules} actions for %{scopes} %{branches} %{agents} %{namespaces} %{period}',
    ),
    selectedBranchesPlaceholder: s__('ScanExecutionPolicy|Select branches'),
  },
  name: 'BaseRuleComponent',
  components: {
    GlButton,
    GlCollapsibleListbox,
    GlFormInput,
    GlSprintf,
  },
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
    return {
      selectedRule: this.defaultSelectedRule[this.selectedKey],
      selectedKey: this.defaultSelectedRule,
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
    rulesListBoxItems() {
      return Object.entries(this.$options.SCAN_EXECUTION_RULES_LABELS).map(([value, text]) => ({
        value,
        text,
      }));
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
    message() {
      return this.initRule.type === SCAN_EXECUTION_RULES_PIPELINE_KEY
        ? this.$options.i18n.pipelineRule
        : this.$options.i18n.scheduleRule;
    },
  },
  methods: {
    setSelectedRule(key) {
      this.selectedRule = this.$options.SCAN_EXECUTION_RULES_LABELS[key];
      this.selectedKey = key;
      this.$emit('select-rule', key);
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
