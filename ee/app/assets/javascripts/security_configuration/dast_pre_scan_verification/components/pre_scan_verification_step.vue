<script>
import { GlButton, GlTooltipDirective as GlTooltip } from '@gitlab/ui';
import { s__ } from '~/locale';
import { PRE_SCAN_VERIFICATION_STATUS } from '../constants';
import PreScanVerificationIcon from './pre_scan_verification_icon.vue';

export default {
  i18n: {
    downloadButtonText: s__('PreScanVerification|Download results'),
  },
  name: 'PreScanVerificationStep',
  directives: {
    GlTooltip,
  },
  components: {
    GlButton,
    PreScanVerificationIcon,
  },
  props: {
    step: {
      type: Object,
      required: true,
    },
    status: {
      type: String,
      required: false,
      default: PRE_SCAN_VERIFICATION_STATUS.DEFAULT,
    },
    showDivider: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    isFailedStatus() {
      return [
        PRE_SCAN_VERIFICATION_STATUS.FAILED,
        PRE_SCAN_VERIFICATION_STATUS.INVALIDATED,
      ].includes(this.status);
    },
    isVerificationFinished() {
      return ![
        PRE_SCAN_VERIFICATION_STATUS.DEFAULT,
        PRE_SCAN_VERIFICATION_STATUS.IN_PROGRESS,
      ].includes(this.status);
    },
    descriptionTextCssClass() {
      return this.isFailedStatus ? 'gl-text-red-500' : 'gl-text-gray-500';
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-gap-5">
    <div class="gl-display-flex gl-flex-direction-column gl-align-items-center">
      <pre-scan-verification-icon :status="status" />
      <div
        v-if="showDivider"
        data-testid="pre-scan-step-divider"
        class="gl-bg-gray-100 gl-translate-x-n50 gl-h-9"
        style="width: 1px"
      ></div>
    </div>
    <div class="gl-pr-4 gl-display-flex gl-align-items-flex-start gl-gap-3">
      <div data-testid="pre-scan-step-content">
        <p class="gl-text-gray-500 gl-font-weight-bold gl-m-0 gl-mb-2">{{ step.header }}</p>
        <p
          data-testid="pre-scan-step-text"
          class="gl-m-0 gl-line-height-normal"
          :class="descriptionTextCssClass"
        >
          {{ step.text }}
        </p>
      </div>
      <gl-button
        v-if="isVerificationFinished"
        v-gl-tooltip
        class="gl-border-0"
        category="tertiary"
        icon="download"
        :title="$options.i18n.downloadButtonText"
      />
    </div>
  </div>
</template>
