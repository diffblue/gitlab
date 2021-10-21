<script>
import { GlSkeletonLoader } from '@gitlab/ui';
import { GlSingleStat } from '@gitlab/ui/dist/charts';
import { STAT_LOADER_HEIGHT } from '../constants';

export default {
  name: 'ThroughputStats',
  components: {
    GlSingleStat,
    GlSkeletonLoader,
  },
  props: {
    stats: {
      type: Array,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  loaderHeight: STAT_LOADER_HEIGHT,
};
</script>
<template>
  <div class="gl-my-7 gl-display-flex">
    <div v-for="stat in stats" :key="stat.title">
      <gl-skeleton-loader v-if="isLoading" :height="$options.loaderHeight" />
      <gl-single-stat
        v-show="!isLoading"
        :value="stat.value"
        :title="stat.title"
        :unit="stat.unit"
        :should-animate="true"
      />
    </div>
  </div>
</template>
