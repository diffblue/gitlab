<script>
import { GlBadge, GlLoadingIcon, GlTooltipDirective as GlTooltip } from '@gitlab/ui';
import { DEFAULT_STYLING, PRE_SCAN_VERIFICATION_STATUS, STATUS_STYLE_MAP } from '../constants';

export default {
  name: 'PreScanVerificationIcon',
  directives: {
    GlTooltip,
  },
  components: {
    GlBadge,
    GlLoadingIcon,
  },
  props: {
    status: {
      type: String,
      required: false,
      default: PRE_SCAN_VERIFICATION_STATUS.DEFAULT,
    },
  },
  computed: {
    isInProgress() {
      return this.status === PRE_SCAN_VERIFICATION_STATUS.IN_PROGRESS;
    },
    statusIcon() {
      return STATUS_STYLE_MAP[this.status]?.icon || DEFAULT_STYLING.icon;
    },
    iconVariant() {
      return STATUS_STYLE_MAP[this.status]?.variant || DEFAULT_STYLING.variant;
    },
  },
};
</script>

<template>
  <gl-loading-icon v-if="isInProgress" :title="status" size="lg" />
  <gl-badge v-else :variant="iconVariant" size="lg" :icon="statusIcon" />
</template>
