<script>
import { GlDropdownItem, GlTooltipDirective as GlTooltip } from '@gitlab/ui';

export default {
  components: { GlDropdownItem },
  directives: { GlTooltip },
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
    tooltip: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    qaSelector() {
      return `filter_${this.text.toLowerCase().replaceAll(' ', '_')}_dropdown_item`;
    },
  },
  methods: {
    emitClick() {
      if (!this.disabled) {
        this.$emit('click');
      }
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
    v-gl-tooltip.left.viewport.d0="tooltip"
    is-check-item
    :is-checked="isChecked"
    :data-qa-selector="qaSelector"
    :disabled="disabled"
    @click.native.capture.stop="emitClick"
  >
    <slot>
      <span :class="{ 'gl-text-gray-600': disabled }">{{ text }}</span>
    </slot>
  </gl-dropdown-item>
</template>
