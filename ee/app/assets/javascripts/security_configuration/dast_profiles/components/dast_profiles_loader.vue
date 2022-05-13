<script>
import { GlCard, GlSkeletonLoader } from '@gitlab/ui';

export default {
  name: 'DastProfilesLoader',
  components: {
    GlCard,
    GlSkeletonLoader,
  },
};
</script>

<template>
  <div>
    <gl-card v-for="i in 5" :key="i" class="gl-mb-5">
      <template #header>
        <gl-skeleton-loader :width="1248" :height="15">
          <rect x="0" y="0" width="300" height="15" rx="4" />
        </gl-skeleton-loader>
      </template>
      <gl-skeleton-loader :width="1248" :height="15">
        <rect x="0" y="0" width="600" height="15" rx="4" />
      </gl-skeleton-loader>
      <gl-skeleton-loader :width="1248" :height="15">
        <rect x="0" y="0" width="300" height="15" rx="4" />
      </gl-skeleton-loader>
    </gl-card>
  </div>
</template>
