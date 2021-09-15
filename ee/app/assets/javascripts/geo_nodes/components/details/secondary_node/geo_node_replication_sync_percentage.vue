<script>
import { roundDownFloat } from '~/lib/utils/common_utils';
import { __ } from '~/locale';

export default {
  name: 'GeoNodeReplicationSyncPercentage',
  i18n: {
    nA: __('N/A'),
  },
  props: {
    values: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    percent() {
      if (!this.values.length) {
        return null;
      }

      const total = this.values.map((v) => v.total).reduce((a, b) => a + b);
      const success = this.values.map((v) => v.success).reduce((a, b) => a + b);

      const percent = roundDownFloat((success / total) * 100, 1);
      if (percent > 0 && percent < 1) {
        // Special case for very small numbers
        return '< 1';
      }

      // If total/success has any null values it will return NaN, lets render N/A for this case too.
      return Number.isNaN(percent) ? null : percent;
    },
    percentColor() {
      if (this.percent === null) {
        return 'gl-bg-gray-200';
      }

      return this.percent === 100 ? 'gl-bg-green-500' : 'gl-bg-red-500';
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-align-items-center gl-flex-grow-1 gl-flex-basis-0">
    <div :class="percentColor" class="gl-rounded-full gl-w-3 gl-h-3 gl-mr-2"></div>
    <span class="gl-font-weight-bold">
      {{ percent === null ? $options.i18n.nA : `${percent}%` }}
    </span>
  </div>
</template>
