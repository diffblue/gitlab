<script>
import GenericBaseLayoutComponent from '../../generic_base_layout_component.vue';
import { getDefaultRule } from '../lib';
import ScanTypeSelect from './scan_type_select.vue';

export default {
  name: 'BaseLayoutComponent',
  components: {
    GenericBaseLayoutComponent,
    ScanTypeSelect,
  },
  props: {
    ruleLabel: {
      type: String,
      required: false,
      default: '',
    },
    type: {
      type: String,
      required: false,
      default: '',
    },
    showScanTypeDropdown: {
      type: Boolean,
      required: false,
      default: false,
    },
    showRemoveButton: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  methods: {
    setScanType(value) {
      const rule = getDefaultRule(value);
      this.$emit('changed', rule);
    },
  },
};
</script>

<template>
  <generic-base-layout-component
    :rule-label="ruleLabel"
    :show-remove-button="showRemoveButton"
    @remove="$emit('remove')"
  >
    <template #selector>
      <slot name="selector">
        <scan-type-select
          v-if="showScanTypeDropdown"
          id="scanType"
          class="gl-display-inline! gl-w-auto gl-vertical-align-middle"
          :scan-type="type"
          @select="setScanType"
        />
      </slot>
    </template>
    <template #content><slot name="content"></slot></template>
  </generic-base-layout-component>
</template>
