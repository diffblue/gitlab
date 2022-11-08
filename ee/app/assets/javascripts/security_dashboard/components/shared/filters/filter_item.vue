<script>
import { GlDropdownItem } from '@gitlab/ui';

export default {
  components: { GlDropdownItem },
  props: {
    isChecked: {
      type: Boolean,
      required: true,
    },
    text: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    qaSelector() {
      return `filter_${this.text.toLowerCase().replace(' ', '_')}_dropdown`;
    },
  },
};
</script>

<template>
  <gl-dropdown-item
    is-check-item
    :is-checked="isChecked"
    :data-qa-selector="qaSelector"
    @click.native.capture.stop="$emit('click')"
  >
    <slot>{{ text }}</slot>
  </gl-dropdown-item>
</template>
