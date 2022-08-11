<script>
import { GlDropdownItem, GlTruncate, GlTooltipDirective as GlTooltip } from '@gitlab/ui';

export default {
  components: { GlDropdownItem, GlTruncate },
  directives: {
    GlTooltip,
  },
  props: {
    isChecked: {
      type: Boolean,
      required: true,
    },
    text: {
      type: String,
      required: true,
      default: '',
    },
    truncate: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    tooltipOptions() {
      return {
        boundary: 'viewport',
        disabled: !this.truncate,
        placement: 'left',
        title: this.text,
      };
    },
    qaSelector() {
      return `filter_${this.text.toLowerCase().replace(' ', '_')}_dropdown`;
    },
  },
};
</script>

<template>
  <span v-gl-tooltip="tooltipOptions">
    <gl-dropdown-item
      is-check-item
      :is-checked="isChecked"
      :data-qa-selector="qaSelector"
      @click.native.capture.stop="$emit('click')"
    >
      <template v-if="truncate">
        <slot>
          <gl-truncate position="middle" :text="text" />
        </slot>
      </template>
      <template v-else>
        <slot>{{ text }}</slot>
      </template>
    </gl-dropdown-item>
  </span>
</template>
