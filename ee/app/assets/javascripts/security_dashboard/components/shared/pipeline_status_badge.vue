<script>
import { GlBadge } from '@gitlab/ui';

export default {
  components: { GlBadge },
  props: {
    pipeline: {
      type: Object,
      required: true,
    },
  },
  computed: {
    failedCount() {
      return this.pipeline.securityBuildsFailedCount || 0;
    },
    failedPath() {
      return this.pipeline.securityBuildsFailedPath || '';
    },
    shouldShow() {
      return this.failedCount > 0;
    },
  },
};
</script>

<template>
  <gl-badge v-if="shouldShow" icon="status_failed" variant="danger" :href="failedPath">
    {{ n__('%d failed security job', '%d failed security jobs', failedCount) }}
  </gl-badge>
</template>
