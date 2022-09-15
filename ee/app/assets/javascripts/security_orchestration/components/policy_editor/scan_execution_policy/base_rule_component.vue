<script>
import { GlButton, GlFormInput, GlSprintf, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { s__ } from '~/locale';
import { slugify } from '../utils';
import { SCAN_EXECUTION_RULES_LABELS } from './constants';

export default {
  SCAN_EXECUTION_RULES_LABELS,
  i18n: {
    scanExecutionRuleCopy: s__(
      'ScanExecutionPolicy|%{ifLabelStart}if%{ifLabelEnd} %{rules} actions for the %{scopes} %{branches}',
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
  },
  data() {
    return {
      selectedRule: this.defaultSelectedRule,
    };
  },
  computed: {
    branchedToAdd: {
      get() {
        return (this.initRule.branches?.length || 0) === 0
          ? ''
          : this.initRule.branches?.filter((element) => element?.trim()).join(',');
      },
      set(values) {
        const branches = slugify(values, ',').split(',').filter(Boolean);
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
  <div class="gl-bg-gray-10 gl-rounded-base gl-px-3 gl-pt-3 gl-relative gl-pb-4">
    <div class="gl-w-full gl-display-flex gl-gap-3 gl-align-items-center gl-flex-wrap">
      <gl-sprintf :message="$options.i18n.scanExecutionRuleCopy">
        <template #ifLabel>
          <label
            for="scanners"
            class="text-uppercase gl-font-lg gl-w-6 gl-pl-2"
            data-testid="rule-component-label"
            >{{ ruleLabel }}</label
          >
        </template>

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
          <gl-form-input
            v-model="branchedToAdd"
            class="gl-mr-3 gl-max-w-34"
            size="lg"
            :placeholder="$options.i18n.selectedBranchesPlaceholder"
            data-testid="rule-branches"
          />
        </template>
      </gl-sprintf>
    </div>

    <slot name="content"></slot>

    <gl-button
      icon="remove"
      category="tertiary"
      class="gl-absolute gl-top-1 gl-right-1"
      :aria-label="__('Remove')"
      data-testid="remove-rule"
      @click="$emit('remove')"
    />
  </div>
</template>
