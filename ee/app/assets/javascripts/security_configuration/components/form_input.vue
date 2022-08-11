<script>
import { GlFormGroup, GlFormInput, GlFormText, GlLink, GlSprintf } from '@gitlab/ui';
import { CUSTOM_VALUE_MESSAGE, SCHEMA_TO_PROP_SIZE_MAP, LARGE } from './constants';

export default {
  components: {
    GlFormGroup,
    GlFormInput,
    GlFormText,
    GlLink,
    GlSprintf,
  },
  // The DynamicFields component v-binds the configuration entity to this
  // component. This ensures extraneous keys/values are not added as attributes
  // to the underlying GlFormGroup.
  inheritAttrs: false,
  model: {
    prop: 'value',
    event: 'input',
  },
  props: {
    value: {
      type: String,
      required: true,
    },
    defaultValue: {
      type: String,
      required: false,
      default: null,
    },
    field: {
      type: String,
      required: true,
    },
    size: {
      type: String,
      required: false,
      default: LARGE,
      validator: (size) => Object.keys(SCHEMA_TO_PROP_SIZE_MAP).includes(size),
    },
    label: {
      type: String,
      required: true,
    },
    description: {
      type: String,
      required: true,
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    placeholder: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    showCustomValueMessage() {
      return this.defaultValue !== null && !this.disabled && this.value !== this.defaultValue;
    },
    inputSize() {
      return SCHEMA_TO_PROP_SIZE_MAP[this.size];
    },
  },
  methods: {
    resetToDefaultValue() {
      this.$emit('input', this.defaultValue);
    },
  },
  i18n: {
    CUSTOM_VALUE_MESSAGE,
  },
};
</script>

<template>
  <gl-form-group :label-for="field">
    <template #label>
      {{ label }}
      <gl-form-text class="gl-mt-3">{{ description }}</gl-form-text>
    </template>

    <gl-form-input
      :id="field"
      :size="inputSize"
      :value="value"
      :disabled="disabled"
      :placeholder="placeholder"
      :data-qa-selector="`${field}_field`"
      @input="$emit('input', $event)"
    />

    <template v-if="showCustomValueMessage" #description>
      <gl-sprintf :message="$options.i18n.CUSTOM_VALUE_MESSAGE">
        <template #anchor="{ content }">
          <gl-link @click="resetToDefaultValue">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </template>
  </gl-form-group>
</template>
