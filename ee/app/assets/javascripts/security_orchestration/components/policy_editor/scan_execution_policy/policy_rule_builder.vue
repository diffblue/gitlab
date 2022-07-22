<script>
import { s__ } from '~/locale';
import { RULE_IF_LABEL, RULE_OR_LABEL } from '../constants';
import PipelineRuleComponent from './pipeline_rule_component.vue';
import ScheduleRuleComponent from './schedule_rule_component.vue';
import { RULE_KEY_MAP } from './lib';
import { SCAN_EXECUTION_PIPELINE_RULE, SCAN_EXECUTION_SCHEDULE_RULE } from './constants';

export default {
  name: 'PolicyRuleBuilder',
  RULE_IF_LABEL,
  RULE_OR_LABEL,
  i18n: {
    scheduleComponentPlaceholder: s__('ScanExecutionPolicy|Schedule rule component'),
  },
  components: {
    PipelineRuleComponent,
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
    ruleLabel() {
      return this.ruleIndex === 0 ? this.$options.RULE_IF_LABEL : this.$options.RULE_OR_LABEL;
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
    <pipeline-rule-component
      v-if="isPipelineRule"
      :init-rule="initRule"
      :rule-label="ruleLabel"
      @select-rule="selectRuleType"
      v-on="$listeners"
    />
    <schedule-rule-component
      v-else-if="isScheduleRule"
      :init-rule="initRule"
      :rule-label="ruleLabel"
      @select-rule="selectRuleType"
      v-on="$listeners"
    />
  </div>
</template>
