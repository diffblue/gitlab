<script>
import { GlTooltipDirective } from '@gitlab/ui';
import { I18N_CELL_FLAG_TRUE_TEXT, I18N_CELL_FLAG_FALSE_TEXT } from '../constants';

export default {
  name: 'DevopsAdoptionTableCellFlag',
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    enabled: {
      type: Boolean,
      required: true,
    },
    variant: {
      type: String,
      required: false,
      default: 'default',
    },
  },
  computed: {
    tooltipText() {
      return this.enabled ? I18N_CELL_FLAG_TRUE_TEXT : I18N_CELL_FLAG_FALSE_TEXT;
    },
  },
};
</script>
<template>
  <span
    v-gl-tooltip.hover="tooltipText"
    class="circle"
    :class="{ [`circle-enabled-${variant}`]: enabled }"
  ></span>
</template>
