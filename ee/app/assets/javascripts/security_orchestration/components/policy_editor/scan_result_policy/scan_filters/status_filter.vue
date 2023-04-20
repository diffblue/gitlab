<script>
import { s__ } from '~/locale';
import PolicyRuleMultiSelect from '../../../policy_rule_multi_select.vue';
import BaseLayoutComponent from '../base_layout/base_layout_component.vue';
import { APPROVAL_VULNERABILITY_STATES } from '../lib';
import { STATUS } from './constants';

export default {
  APPROVAL_VULNERABILITY_STATES,
  i18n: {
    label: s__('ScanResultPolicy|Status is:'),
    headerText: s__('ScanResultPolicy|Choose an option'),
    vulnerabilityStates: s__('ScanResultPolicy|vulnerability states'),
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
      vulnerabilityStates: this.selected,
    };
  },
  methods: {
    remove() {
      this.$emit('remove', STATUS);
    },
    selectVulnerabilityStates(states) {
      this.vulnerabilityStates = states;
      this.$emit('input', this.vulnerabilityStates);
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
      <label class="gl-mb-0 gl-mr-4" :title="$options.i18n.label">{{ $options.i18n.label }}</label>
      <slot>
        <policy-rule-multi-select
          v-model="vulnerabilityStates"
          :item-type-name="$options.i18n.vulnerabilityStates"
          :items="$options.APPROVAL_VULNERABILITY_STATES"
          data-testid="vulnerability-states-select"
          @input="selectVulnerabilityStates"
        />
      </slot>
    </template>
  </base-layout-component>
</template>
