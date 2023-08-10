<script>
import { GlBadge, GlButton } from '@gitlab/ui';

export default {
  components: {
    GlBadge,
    GlButton,
  },
  inject: {
    runnerDashboardPath: {
      default: null,
    },
  },
};
</script>
<template>
  <gl-button v-if="runnerDashboardPath" variant="link" :href="runnerDashboardPath">
    {{ s__('Runners|Fleet dashboard')
    }}<gl-badge variant="info" size="sm" class="gl-ml-1">{{ s__('Runners|New') }}</gl-badge>
  </gl-button>
</template>
