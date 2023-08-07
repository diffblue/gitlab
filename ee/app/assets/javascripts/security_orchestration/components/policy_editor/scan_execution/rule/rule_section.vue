<script>
import { s__ } from '~/locale';
import { RULE_OR_LABEL } from '../../constants';
import { RULE_KEY_MAP } from '../lib';
import {
  SCAN_EXECUTION_PIPELINE_RULE,
  SCAN_EXECUTION_SCHEDULE_RULE,
  SCAN_EXECUTION_RULES_LABELS,
  SCAN_EXECUTION_RULES_PIPELINE_KEY,
} from '../constants';
import BaseRuleComponent from './base_rule_component.vue';
import ScheduleRuleComponent from './schedule_rule_component.vue';

export default {
  SCAN_EXECUTION_RULES_LABELS,
  SCAN_EXECUTION_RULES_PIPELINE_KEY,
  name: 'RuleSection',
  RULE_OR_LABEL,
  i18n: {
    scheduleComponentPlaceholder: s__('ScanExecutionPolicy|Schedule rule component'),
  },
  components: {
    BaseRuleComponent,
    ScheduleRuleComponent,
  },
  props: {
    initRule: {
      type: Object,
      required: true,
    },
    ruleIndex: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  computed: {
    isPipelineRule() {
      return this.initRule.type === SCAN_EXECUTION_PIPELINE_RULE;
    },
    isScheduleRule() {
      return this.initRule.type === SCAN_EXECUTION_SCHEDULE_RULE;
    },
    isFirstRule() {
      return this.ruleIndex === 0;
    },
  },
  methods: {
    selectRuleType(type) {
      this.$emit('changed', RULE_KEY_MAP[type]());
    },
  },
};
</script>

<template>
  <div>
    <div v-if="!isFirstRule" class="gl-text-gray-500 gl-mb-4 gl-ml-5" data-testid="rule-separator">
      {{ $options.RULE_OR_LABEL }}
    </div>
    <base-rule-component
      v-if="isPipelineRule"
      :default-selected-rule="$options.SCAN_EXECUTION_RULES_PIPELINE_KEY"
      :init-rule="initRule"
      v-on="$listeners"
      @select-rule="selectRuleType"
    />
    <schedule-rule-component
      v-else-if="isScheduleRule"
      :init-rule="initRule"
      @select-rule="selectRuleType"
      v-on="$listeners"
    />
  </div>
</template>
