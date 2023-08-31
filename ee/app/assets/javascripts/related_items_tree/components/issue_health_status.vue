<script>
import { GlBadge, GlTooltipDirective } from '@gitlab/ui';
import { healthStatusTextMap, healthStatusVariantMap } from 'ee/sidebar/constants';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlBadge,
  },
  props: {
    healthStatus: {
      type: String,
      required: true,
      validator: (value) => Object.keys(healthStatusTextMap).includes(value),
    },
  },
  computed: {
    statusText() {
      return healthStatusTextMap[this.healthStatus];
    },
    statusClass() {
      return healthStatusVariantMap[this.healthStatus];
    },
  },
};
</script>

<template>
  <gl-badge
    v-gl-tooltip
    class="gl-font-weight-bold"
    size="sm"
    :title="__('Health status')"
    :variant="statusClass"
  >
    {{ statusText }}
  </gl-badge>
</template>
