<script>
import { s__ } from '~/locale';
import { SEVERITY_LEVELS } from 'ee/security_dashboard/store/constants';
import PolicyRuleMultiSelect from '../../../policy_rule_multi_select.vue';
import BaseLayoutComponent from '../base_layout/base_layout_component.vue';
import { SEVERITY } from './constants';

export default {
  SEVERITY_LEVELS,
  i18n: {
    label: s__('ScanResultPolicy|Severity is:'),
    severityLevels: s__('ScanResultPolicy|severity levels'),
  },
  name: 'SeverityFilter',
  components: {
    PolicyRuleMultiSelect,
    BaseLayoutComponent,
  },
  props: {
    selected: {
      type: Array,
      required: false,
      default: () => [],
    },
    showRemoveButton: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  data() {
    return {
      severityLevelsToAdd: this.selected,
    };
  },
  methods: {
    remove() {
      this.$emit('remove', SEVERITY);
    },
    selectSeverities(states) {
      this.severityLevelsToAdd = states;
      this.$emit('input', this.severityLevelsToAdd);
    },
  },
};
</script>

<template>
  <base-layout-component
    class="gl-w-full"
    content-class="gl-bg-white gl-rounded-base gl-p-5"
    :show-label="false"
    :show-remove-button="showRemoveButton"
    @remove="remove"
  >
    <template #selector>
      <label class="gl-mb-0" :title="$options.i18n.label">{{ $options.i18n.label }}</label>
      <policy-rule-multi-select
        v-model="severityLevelsToAdd"
        :item-type-name="$options.i18n.severityLevels"
        :items="$options.SEVERITY_LEVELS"
        data-testid="severities-select"
        @input="selectSeverities"
      />
    </template>
  </base-layout-component>
</template>
