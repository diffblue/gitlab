<script>
import { roundDownFloat } from '~/lib/utils/common_utils';

export default {
  name: 'GeoSiteReplicationSyncPercentage',
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

      // Display Not applicable when percent is not valide.
      return Number.isFinite(percent) ? percent : null;
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
  <div class="gl-display-flex gl-align-items-center gl-justify-content-end">
    <div
      :class="percentColor"
      class="gl-rounded-full gl-w-3 gl-h-3 gl-mr-2"
      data-testid="geo-sync-percentage-indicator"
    ></div>
    <span class="gl-font-weight-bold" data-testid="geo-sync-percentage">
      {{ percent === null ? `-%` : `${percent}%` }}
    </span>
  </div>
</template>
