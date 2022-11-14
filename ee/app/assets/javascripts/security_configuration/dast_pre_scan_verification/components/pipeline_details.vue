<script>
import { GlLink } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { PRE_SCAN_VERIFICATION_STATUS } from '../constants';

export default {
  i18n: {
    preScanVerificationInProgressText: s__('PreScanVerification|Started %{timeAgo} in pipeline'),
    preScanVerificationText: s__('PreScanVerification|Last run %{timeAgo} in pipeline'),
  },
  name: 'PipelineDetails',
  components: {
    GlLink,
  },
  mixins: [timeagoMixin],
  props: {
    status: {
      type: String,
      required: false,
      default: PRE_SCAN_VERIFICATION_STATUS.IN_PROGRESS,
    },
    isLowerCase: {
      type: Boolean,
      required: false,
      default: false,
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
    pipelineIdFormatted() {
      return `#${this.pipelineId}`;
    },
    preScanVerificationPipelineInfo() {
      return sprintf(this.statusInfoMessage, {
        timeAgo: this.timeAgo,
      });
    },
    preScanVerificationPipelineInfoCase() {
      return this.isLowerCase
        ? this.preScanVerificationPipelineInfo.toLowerCase()
        : this.preScanVerificationPipelineInfo;
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
};
</script>

<template>
  <div data-testid="status-message">
    <span>{{ preScanVerificationPipelineInfoCase }}</span>
    <gl-link v-if="verificationUsedBefore" :href="pipelinePath">
      {{ pipelineIdFormatted }}
    </gl-link>
  </div>
</template>
