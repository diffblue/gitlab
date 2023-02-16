<script>
import { GlFormCheckbox } from '@gitlab/ui';
import ApprovalSettingsLockedIcon from './approval_settings_locked_icon.vue';

export default {
  components: {
    ApprovalSettingsLockedIcon,
    GlFormCheckbox,
  },
  props: {
    label: {
      type: String,
      required: true,
    },
    checked: {
      type: Boolean,
      required: false,
      default: false,
    },
    locked: {
      type: Boolean,
      required: false,
      default: false,
    },
    lockedText: {
      type: String,
      required: false,
      default: '',
    },
  },
  methods: {
    input(value) {
      this.$emit('input', value);
    },
  },
};
</script>

<template>
  <gl-form-checkbox :disabled="locked" :checked="checked" @input="input">
    {{ label }}
    <approval-settings-locked-icon v-if="locked" :label="label" :locked-text="lockedText" />
    <template #help>
      <slot name="help"></slot>
    </template>
  </gl-form-checkbox>
</template>
