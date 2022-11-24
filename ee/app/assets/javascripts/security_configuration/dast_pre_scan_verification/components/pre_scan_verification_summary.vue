<script>
import { GlIcon, GlTooltipDirective as GlTooltip } from '@gitlab/ui';
import {
  DEFAULT_STYLING_SUMMARY_STYLING,
  PRE_SCAN_VERIFICATION_STATUS_LABEL_MAP,
  PRE_SCAN_VERIFICATION_STATUS,
  SUMMARY_STATUS_STYLE_MAP,
  STATUS_LABEL_MAP,
} from '../constants';
import PipelineDetails from './pipeline_details.vue';

export default {
  name: 'PreScanVerificationSummary',
  directives: {
    GlTooltip,
  },
  components: {
    GlIcon,
    PipelineDetails,
  },
  props: {
    status: {
      type: String,
      required: false,
      default: PRE_SCAN_VERIFICATION_STATUS_LABEL_MAP[PRE_SCAN_VERIFICATION_STATUS.DEFAULT],
    },
  },
  computed: {
    styling() {
      return SUMMARY_STATUS_STYLE_MAP[this.status] || DEFAULT_STYLING_SUMMARY_STYLING;
    },
    statusLabel() {
      return (
        STATUS_LABEL_MAP[this.status] || STATUS_LABEL_MAP[PRE_SCAN_VERIFICATION_STATUS.COMPLETE]
      );
    },
    tooltipLabel() {
      return PRE_SCAN_VERIFICATION_STATUS_LABEL_MAP[this.status];
    },
  },
};
</script>

<template>
  <div class="gl-bg-gray-50 gl-rounded-base gl-mx-6 gl-border-0 gl-mb-5">
    <pipeline-details
      class="gl-mb-4 gl-text-gray-50"
      :status="status"
      pipeline-id="2343434"
      pipeline-created-at="2022-09-23 11:19:49 UTC"
      pipeline-path="test-path"
    />
    <div
      v-gl-tooltip
      :title="tooltipLabel"
      class="gl-display-flex gl-py-2 gl-align-items-center gl-justify-content-center gl-border gl-rounded-base gl-bg-white"
      data-testid="pre-scan-status"
      :style="styling.borderColor"
    >
      <gl-icon :name="styling.icon" :class="styling.iconColor" :aria-label="styling.icon" />
      <span class="gl-ml-2" :class="styling.iconColor">{{ statusLabel }}</span>
    </div>
  </div>
</template>
