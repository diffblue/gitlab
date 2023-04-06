<script>
import { GlButton } from '@gitlab/ui';
import { getDefaultRule } from '../lib';
import ScanTypeSelect from './scan_type_select.vue';

export default {
  name: 'BaseLayoutComponent',
  components: {
    GlButton,
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
  computed: {
    showLabel() {
      return Boolean(this.ruleLabel);
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
  <div class="gl-display-flex gl-gap-3 security-policies-bg-gray-10 gl-rounded-base gl-p-5">
    <div v-if="showLabel" class="gl-min-w-7">
      <label
        data-testid="base-label"
        for="content"
        class="gl-text-transform-uppercase gl-font-lg gl-w-6 gl-pl-2"
      >
        {{ ruleLabel }}
      </label>
    </div>

    <div
      id="content"
      class="gl-flex-grow-1 gl-w-full gl-display-flex gl-gap-3 gl-align-items-center gl-flex-wrap"
    >
      <slot name="selector">
        <scan-type-select
          v-if="showScanTypeDropdown"
          id="scanType"
          class="gl-display-inline! gl-w-auto gl-vertical-align-middle"
          :scan-type="type"
          @select="setScanType"
        />
      </slot>
      <slot name="content"></slot>
    </div>

    <div v-if="showRemoveButton" class="gl-min-w-7 gl-ml-4">
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
