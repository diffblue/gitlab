<script>
import { GlSkeletonLoader } from '@gitlab/ui';

export default {
  components: {
    GlSkeletonLoader,
  },
};
</script>

<template>
  <gl-skeleton-loader :width="640" :height="276">
    <rect x="0" y="0" width="150" height="60" rx="2" />
    <rect x="166" y="0" width="150" height="60" rx="2" />
    <rect x="0" y="76" width="640" height="200" rx="2" />
  </gl-skeleton-loader>
</template>
