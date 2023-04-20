<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';

export default {
  components: {
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['hasIssueWeightsFeature'],
  props: {
    weight: {
      type: Number,
      required: false,
      default: null,
    },
  },
  computed: {
    showWeight() {
      return this.hasIssueWeightsFeature && this.weight != null;
    },
  },
};
</script>

<template>
  <span v-if="showWeight" v-gl-tooltip :title="__('Weight')">
    <gl-icon name="weight" :size="12" />
    {{ weight }}
  </span>
</template>
