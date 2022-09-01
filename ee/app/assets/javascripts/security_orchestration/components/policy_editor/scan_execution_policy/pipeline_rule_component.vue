<script>
import BaseRuleComponent from './base_rule_component.vue';
import { SCAN_EXECUTION_RULES_LABELS } from './constants';

export default {
  SCAN_EXECUTION_RULES_LABELS,
  name: 'PipelineRuleComponent',
  components: {
    BaseRuleComponent,
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
};
</script>

<template>
  <base-rule-component
    :default-selected-rule="$options.SCAN_EXECUTION_RULES_LABELS.pipeline"
    :init-rule="initRule"
    :rule-label="ruleLabel"
    v-on="$listeners"
  />
</template>
