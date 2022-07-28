<script>
import { s__ } from '~/locale';
import { RULE_IF_LABEL, RULE_OR_LABEL } from '../constants';
import PipelineRuleComponent from './pipeline_rule_component.vue';
import { RULE_KEY_MAP } from './lib/rules';

export default {
  name: 'PolicyRuleBuilder',
  RULE_IF_LABEL,
  RULE_OR_LABEL,
  i18n: {
    scheduleComponentPlaceholder: s__('ScanExecutionPolicy|Schedule rule component'),
  },
  components: {
    PipelineRuleComponent,
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
      :init-rule="initRule"
      :rule-label="ruleLabel"
      @select-rule="selectRuleType"
      v-on="$listeners"
    />
    <!--TO DO Schedule Rule Component-->
  </div>
</template>
