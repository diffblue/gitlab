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
    disabled: {
      type: Boolean,
      required: false,
      default: false,
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
  <!-- 
    // Once GlDropdownItem support a disabled state, the custom classes can be removed
    // See https://gitlab.com/gitlab-org/gitlab-ui/-/issues/2092
   -->
  <gl-dropdown-item
    is-check-item
    :is-checked="isChecked"
    :data-qa-selector="qaSelector"
    :disabled="disabled"
    :class="{ 'gl-pointer-events-none': disabled }"
    @click.native.capture.stop="$emit('click')"
  >
    <slot>
      <span :class="{ 'gl-text-gray-600': disabled }">{{ text }}</span>
    </slot>
  </gl-dropdown-item>
</template>
