<script>
import { GlTooltipDirective } from '@gitlab/ui';
import { issueHealthStatus, issueHealthStatusCSSMapping } from '../constants';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    healthStatus: {
      type: String,
      required: true,
    },
  },
  computed: {
    statusText() {
      return issueHealthStatus[this.healthStatus];
    },
    statusClass() {
      return issueHealthStatusCSSMapping[this.healthStatus];
    },
  },
};
</script>

<template>
  <div class="health-status">
    <span class="gl-label gl-label-sm" :class="statusClass">
      <span v-gl-tooltip class="gl-label-text" :title="__('Health status')">
        {{ statusText }}
      </span>
    </span>
  </div>
</template>
