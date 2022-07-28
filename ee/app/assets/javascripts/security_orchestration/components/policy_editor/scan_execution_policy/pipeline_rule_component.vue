<script>
import { GlButton, GlFormInput, GlSprintf, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { s__ } from '~/locale';
import { slugify } from '~/lib/utils/text_utility';
import { SCAN_EXECUTION_RULES_LABELS } from './constants';

export default {
  SCAN_EXECUTION_RULES_LABELS,
  i18n: {
    scanExecutionRuleCopy: s__(
      'ScanExecutionPolicy|%{ifLabelStart}if%{ifLabelEnd} %{rules} for the %{branches} branch(es)',
    ),
    selectedBranchesPlaceholder: s__('ScanExecutionPolicy|Select branches'),
  },
  name: 'PipelineRuleComponent',
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
  },
  data() {
    return {
      selectedRule: this.$options.SCAN_EXECUTION_RULES_LABELS.pipeline,
    };
  },
  computed: {
    branchedToAdd: {
      get() {
        return this.initRule.branches.length === 0
          ? ''
          : this.initRule.branches.filter((element) => element?.trim()).join(',');
      },
      set(values) {
        const branches = slugify(values, ',').split(',').filter(Boolean);
        this.triggerChanged({
          branches,
        });
      },
    },
  },
  methods: {
    triggerChanged(value) {
      this.$emit('changed', { ...this.initRule, ...value });
    },
    isSelected(key) {
      return this.selectedRule === this.$options.SCAN_EXECUTION_RULES_LABELS[key];
    },
    setSelected(key) {
      this.selectedRule = this.$options.SCAN_EXECUTION_RULES_LABELS[key];
      this.$emit('select-rule', key);
    },
  },
};
</script>

<template>
  <div>
    <div class="gl-bg-gray-10 gl-rounded-base gl-px-3 gl-pt-3 gl-relative gl-pb-4">
      <div class="form-inline">
        <gl-sprintf :message="$options.i18n.scanExecutionRuleCopy">
          <template #ifLabel>
            <label
              for="scanners"
              class="text-uppercase gl-min-w-7 gl-font-lg gl-mr-3"
              data-testid="rule-component-label"
              >{{ ruleLabel }}</label
            >
          </template>

          <template #rules>
            <gl-dropdown class="gl-mr-3" :text="selectedRule" data-testid="rule-component-type">
              <gl-dropdown-item
                v-for="(label, key) in $options.SCAN_EXECUTION_RULES_LABELS"
                :key="key"
                is-check-item
                :is-checked="isSelected(key)"
                @click="setSelected(key)"
              >
                {{ label }}
              </gl-dropdown-item>
            </gl-dropdown>
          </template>

          <template #branches>
            <gl-form-input
              v-model="branchedToAdd"
              class="gl-ml-3 gl-mr-3"
              :placeholder="$options.i18n.selectedBranchesPlaceholder"
              data-testid="pipeline-rule-branches"
            />
          </template>
        </gl-sprintf>
      </div>
      <gl-button
        icon="remove"
        category="tertiary"
        class="gl-absolute gl-top-1 gl-right-1"
        :aria-label="__('Remove')"
        data-testid="remove-rule"
        @click="$emit('remove')"
      />
    </div>
  </div>
</template>
