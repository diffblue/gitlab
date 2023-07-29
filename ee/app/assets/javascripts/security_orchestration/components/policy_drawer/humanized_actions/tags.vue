<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlBadge } from '@gitlab/ui';

export default {
  components: {
    GlBadge,
  },
  props: {
    criteria: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <div v-if="criteria.tags.length" class="gl-mt-2 gl-display-flex gl-gap-2 gl-flex-wrap">
    <gl-badge v-for="tag in criteria.tags" :key="tag" variant="info" size="sm">
      {{ tag }}
    </gl-badge>
  </div>
</template>
