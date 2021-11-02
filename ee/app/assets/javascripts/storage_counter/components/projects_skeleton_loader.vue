<script>
import { GlSkeletonLoader } from '@gitlab/ui';
import { SKELETON_LOADER_ROWS } from '../constants';

export default {
  name: 'ProjectsSkeletonLoader',
  components: { GlSkeletonLoader },
  SKELETON_LOADER_ROWS,
};
</script>
<template>
  <div class="gl-border-b-solid gl-border-b-1 gl-border-gray-100">
    <div class="gl-flex-direction-column gl-md-display-none" data-testid="mobile-loader">
      <div
        v-for="index in $options.SKELETON_LOADER_ROWS"
        :key="index"
        class="gl-responsive-table-row gl-border-solid gl-border-b-1 gl-pt-3 gl-pb-3 gl-border-b-gray-100"
      >
        <gl-skeleton-loader :width="500" :height="110">
          <rect width="480" height="20" x="10" y="15" rx="4" />
          <rect width="480" height="20" x="10" y="80" rx="4" />
        </gl-skeleton-loader>
      </div>
    </div>
    <div
      class="gl-display-none gl-md-display-flex gl-flex-direction-column"
      data-testid="desktop-loader"
    >
      <gl-skeleton-loader
        v-for="index in $options.SKELETON_LOADER_ROWS"
        :key="index"
        :width="1000"
        :height="39"
      >
        <rect rx="4" width="320" height="8" x="0" y="18" />
        <rect rx="4" width="60" height="8" x="700" y="18" />
      </gl-skeleton-loader>
    </div>
  </div>
</template>
