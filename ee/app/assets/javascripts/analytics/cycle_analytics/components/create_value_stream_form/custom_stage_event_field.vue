<script>
import { GlFormGroup, GlDropdown, GlDropdownItem } from '@gitlab/ui';

export default {
  name: 'CustomStageEventField',
  components: {
    GlFormGroup,
    GlDropdown,
    GlDropdownItem,
  },
  props: {
    index: {
      type: Number,
      required: true,
    },
    eventType: {
      type: String,
      required: true,
    },
    eventsList: {
      type: Array,
      required: true,
    },
    fieldLabel: {
      type: String,
      required: true,
    },
    selectedEventName: {
      type: String,
      required: true,
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    hasIdentifierError: {
      type: Boolean,
      required: false,
      default: false,
    },
    identifierError: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    fieldName() {
      const { eventType, index } = this;
      return `custom-stage-${eventType}-${index}`;
    },
  },
};
</script>
<template>
  <gl-form-group
    class="gl-w-half gl-mr-2"
    :data-testid="fieldName"
    :label="fieldLabel"
    :state="hasIdentifierError"
    :invalid-feedback="identifierError"
  >
    <gl-dropdown
      toggle-class="gl-mb-0"
      :text="selectedEventName"
      :name="fieldName"
      :disabled="disabled"
      menu-class="gl-overflow-hidden!"
      block
    >
      <gl-dropdown-item
        v-for="{ text, value } in eventsList"
        :key="`${eventType}-${value}`"
        :value="value"
        @click="$emit('update-identifier', value)"
        >{{ text }}</gl-dropdown-item
      >
    </gl-dropdown>
  </gl-form-group>
</template>
