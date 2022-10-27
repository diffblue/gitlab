<script>
import { GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';
import { PRE_SCAN_VERIFICATION_STATUS } from '../constants';
import PreScanVerificationIcon from './pre_scan_verification_icon.vue';
import PipelineDetails from './pipeline_details.vue';

export default {
  name: 'PreScanVerificationStatus',
  components: {
    GlButton,
    PreScanVerificationIcon,
    PipelineDetails,
  },
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
    isDefaultStatus() {
      return this.status === PRE_SCAN_VERIFICATION_STATUS.DEFAULT;
    },
    verificationButtonText() {
      return this.isDefaultStatus
        ? this.$options.i18n.verifyConfigurationButton
        : this.$options.i18n.viewResultsButton;
    },
  },
  i18n: {
    preScanVerificationHeader: s__('PreScanVerification|Pre-scan verification'),
    preScanVerificationLabel: s__('PreScanVerification|(optional)'),
    preScanVerificationDefaultText: s__(
      'PreScanVerification|Test your configuration and identify potential errors before running a full scan.',
    ),
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
        <pipeline-details
          v-else
          class="gl-text-gray-500"
          :status="status"
          :pipeline-id="pipelineId"
          :pipeline-path="pipelinePath"
          :pipeline-created-at="pipelineCreatedAt"
        />
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
