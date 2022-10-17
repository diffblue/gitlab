<script>
import { GlButton, GlLink } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { PRE_SCAN_VERIFICATION_STATUS } from '../constants';
import PreScanVerificationIcon from './pre_scan_verification_icon.vue';

export default {
  name: 'PreScanVerificationStatus',
  components: {
    GlButton,
    GlLink,
    PreScanVerificationIcon,
  },
  mixins: [timeagoMixin],
  props: {
    status: {
      type: String,
      required: false,
      default: PRE_SCAN_VERIFICATION_STATUS.DEFAULT,
    },
    pipelineId: {
      type: String,
      required: false,
      default: '',
    },
    pipelineCreatedAt: {
      type: String,
      required: false,
      default: '',
    },
    pipelinePath: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    verificationUsedBefore() {
      return Boolean(this.pipelineCreatedAt);
    },
    verificationButtonText() {
      return this.isDefaultStatus
        ? this.$options.i18n.verifyConfigurationButton
        : this.$options.i18n.viewResultsButton;
    },
    isDefaultStatus() {
      return this.status === PRE_SCAN_VERIFICATION_STATUS.DEFAULT;
    },
    pipelineIdFormatted() {
      return `#${this.pipelineId}`;
    },
    preScanVerificationPipelineInfo() {
      return sprintf(this.statusInfoMessage, {
        timeAgo: this.timeAgo,
      });
    },
    statusInfoMessage() {
      return this.status === PRE_SCAN_VERIFICATION_STATUS.IN_PROGRESS
        ? this.$options.i18n.preScanVerificationInProgressText
        : this.$options.i18n.preScanVerificationText;
    },
    timeAgo() {
      return this.timeFormatted(this.pipelineCreatedAt);
    },
  },
  i18n: {
    preScanVerificationHeader: s__('PreScanVerification|Pre-scan verification'),
    preScanVerificationLabel: s__('PreScanVerification|(optional)'),
    preScanVerificationDefaultText: s__(
      'PreScanVerification|Test your configuration and identify potential errors before running a full scan.',
    ),
    preScanVerificationInProgressText: s__('PreScanVerification|Started %{timeAgo} in pipeline'),
    preScanVerificationText: s__('PreScanVerification|Last run %{timeAgo} in pipeline'),
    verifyConfigurationButton: s__('PreScanVerification|Verify configuration'),
    viewResultsButton: s__('PreScanVerification|View results'),
  },
};
</script>

<template>
  <div
    class="gl-bg-gray-10 gl-border gl-rounded-base gl-p-5 gl-w-full gl-display-flex gl-gap-3 gl-align-items-center"
  >
    <pre-scan-verification-icon :status="status" />

    <div class="gl-flex-grow-1">
      <h3 class="gl-m-0 gl-mb-1 gl-font-lg">
        {{ $options.i18n.preScanVerificationHeader }}
        <span class="gl-ml-1 gl-text-gray-500 gl-font-base gl-font-weight-300">
          {{ $options.i18n.preScanVerificationLabel }}
        </span>
      </h3>
      <div data-testid="status-message">
        <span v-if="isDefaultStatus" class="gl-text-gray-500">{{
          $options.i18n.preScanVerificationDefaultText
        }}</span>
        <span v-else class="gl-text-gray-500">
          <span data-testid="dast-header-text">{{ preScanVerificationPipelineInfo }}</span>
          <gl-link v-if="verificationUsedBefore" :href="pipelinePath" data-testid="help-page-link">
            {{ pipelineIdFormatted }}
          </gl-link>
        </span>
      </div>
    </div>

    <div class="gl-align-self-center">
      <gl-button
        data-testid="pre-scan-results-btn"
        variant="default"
        category="primary"
        @click="$emit('select-results')"
        >{{ verificationButtonText }}</gl-button
      >
    </div>
  </div>
</template>
