<script>
import { GlIcon } from '@gitlab/ui';
import { formatMetric } from '../utils';
import { UNITS } from '../constants';

export default {
  name: 'TrendIndicator',
  components: {
    GlIcon,
  },
  props: {
    change: {
      type: Number,
      required: true,
    },

    // By default `change` will be rendered: +green/-red
    // `invertColor = true` will render the opposite: +red/-green
    invertColor: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    trendingUp() {
      return this.change > 0;
    },
    textColor() {
      return this.trendingUp !== this.invertColor ? 'gl-text-green-500' : 'gl-text-red-500';
    },
    iconName() {
      return this.trendingUp ? 'trend-up' : 'trend-down';
    },
    formattedChange() {
      return formatMetric(Math.abs(this.change * 100), UNITS.PERCENT);
    },
  },
};
</script>
<template>
  <span :class="`gl-ml-3 gl-font-sm ${textColor}`">
    <gl-icon :name="iconName" />
    {{ formattedChange }}
  </span>
</template>
