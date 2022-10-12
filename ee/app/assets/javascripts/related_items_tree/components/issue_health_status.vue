<script>
import { GlBadge, GlTooltipDirective } from '@gitlab/ui';
import { issueHealthStatus, issueHealthStatusVariantMapping } from '../constants';

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
      validator: (value) => Object.keys(issueHealthStatus).includes(value),
    },
  },
  computed: {
    statusText() {
      return issueHealthStatus[this.healthStatus];
    },
    statusClass() {
      return issueHealthStatusVariantMapping[this.healthStatus];
    },
  },
};
</script>

<template>
  <span ref="healthStatus" class="health-status">
    <gl-badge
      v-gl-tooltip
      title="Health status"
      class="gl-font-weight-bold"
      size="sm"
      :variant="statusClass"
    >
      {{ statusText }}
    </gl-badge>
  </span>
</template>
