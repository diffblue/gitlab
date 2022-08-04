<script>
import { GlFormRadio } from '@gitlab/ui';
import ApprovalSettingsLockedIcon from './approval_settings_locked_icon.vue';

export default {
  components: {
    ApprovalSettingsLockedIcon,
    GlFormRadio,
  },
  props: {
    label: {
      type: String,
      required: true,
    },
    value: {
      type: String,
      required: true,
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
    name: {
      type: String,
      required: true,
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
  <gl-form-radio :disabled="locked" :name="name" :value="value" @input="input">
    {{ label }}
    <approval-settings-locked-icon v-if="locked" :label="label" :locked-text="lockedText" />
  </gl-form-radio>
</template>
