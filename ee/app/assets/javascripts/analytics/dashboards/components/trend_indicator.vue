<script>
import { GlIcon } from '@gitlab/ui';
import { percent } from '~/lib/utils/unit_format';

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
  },
  computed: {
    textColor() {
      return this.change > 0 ? 'gl-text-green-500' : 'gl-text-red-500';
    },
    iconName() {
      return this.change > 0 ? 'trend-up' : 'trend-down';
    },
    formattedChange() {
      return percent(Math.abs(this.change), 1);
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
