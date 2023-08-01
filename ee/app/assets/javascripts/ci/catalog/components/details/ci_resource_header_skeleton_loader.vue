<script>
import { GlSkeletonLoader } from '@gitlab/ui';

export default {
  components: {
    GlSkeletonLoader,
  },
  data() {
    return {
      width: 0,
    };
  },
  mounted() {
    this.setSVGWidth();
  },
  methods: {
    setSVGWidth() {
      this.width = this.$el.offsetWidth;
    },
  },
};
</script>

<template>
  <div class="gl-w-full">
    <gl-skeleton-loader :width="width" :height="116">
      <!-- Catalog project avatar -->
      <rect x="0" y="0" width="64" height="64" rx="4" ry="4" />
      <!-- namespace path -->
      <rect x="78" y="12" width="150" height="12" rx="2" ry="2" />
      <!-- Component respository name -->
      <rect x="78" y="32" width="180" height="18" rx="2" ry="2" />
      <!-- Project description -->
      <rect x="0" y="85" width="300" height="18" rx="2" ry="2" />
    </gl-skeleton-loader>
  </div>
</template>
