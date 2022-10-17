<script>
import { GlIcon, GlLoadingIcon, GlTooltipDirective as GlTooltip } from '@gitlab/ui';
import { DEFAULT_STYLING, PRE_SCAN_VERIFICATION_STATUS, STATUS_STYLE_MAP } from '../constants';

export default {
  name: 'PreScanVerificationIcon',
  directives: {
    GlTooltip,
  },
  components: {
    GlIcon,
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
    bgColorClass() {
      return STATUS_STYLE_MAP[this.status]?.bgColor || DEFAULT_STYLING.bgColor;
    },
    iconColoClass() {
      return STATUS_STYLE_MAP[this.status]?.iconColor || DEFAULT_STYLING.iconColor;
    },
  },
};
</script>

<template>
  <gl-loading-icon v-if="isInProgress" :title="status" size="lg" />
  <div
    v-else
    data-testid="pre-scan-verification-icon-wrapper"
    class="gl-w-7 gl-h-7 gl-display-flex gl-align-items-center gl-justify-content-center gl-rounded-full gl-bg-gray-100"
    :class="bgColorClass"
  >
    <gl-icon
      v-gl-tooltip
      data-testid="pre-scan-verification-icon"
      :class="iconColoClass"
      :title="status"
      :name="statusIcon"
      :aria-label="statusIcon"
    />
  </div>
</template>
