<script>
import { GlDrawer } from '@gitlab/ui';
import { s__ } from '~/locale';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { PRE_SCAN_VERIFICATION_STATUS } from '../constants';
import PreScanVerificationAlert from './pre_scan_verification_alert.vue';
import PreScanVerificationList from './pre_scan_verification_list.vue';
import PreScanVerificationSummary from './pre_scan_verification_summary.vue';

export default {
  i18n: {
    preScanVerificationSidebarHeader: s__('PreScanVerification|Pre-scan verification'),
    preScanVerificationSidebarInfo: s__(
      'PreScanVerification|Test your configuration and identify potential errors before running a full scan.',
    ),
  },
  name: 'PreScanVerificationSidebar',
  components: {
    GlDrawer,
    PreScanVerificationAlert,
    PreScanVerificationList,
    PreScanVerificationSummary,
  },
  props: {
    open: {
      type: Boolean,
      required: false,
      default: false,
    },
    status: {
      type: String,
      required: false,
      default: PRE_SCAN_VERIFICATION_STATUS.DEFAULT,
    },
    showAlert: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    isDefaultStatus() {
      return this.status === PRE_SCAN_VERIFICATION_STATUS.DEFAULT;
    },
    getDrawerHeaderHeight() {
      return getContentWrapperHeight('.nav-sidebar');
    },
  },
};
</script>

<template>
  <gl-drawer
    :header-height="getDrawerHeaderHeight"
    :header-sticky="true"
    :open="open"
    :z-index="1001"
    @close="$emit('close')"
  >
    <template #title>
      <h4 data-testid="sidebar-header" class="gl-font-size-h2 gl-my-0">
        {{ $options.i18n.preScanVerificationSidebarHeader }}
      </h4>
    </template>
    <template #default>
      <pre-scan-verification-alert
        v-if="showAlert"
        pipeline-created-at="2022-09-23 11:19:49 UTC"
        :status="status"
        class="gl-px-9! gl-py-5! gl-mx-6 gl-mt-5 gl-border-0"
        @dismiss="$emit('dismiss-alert')"
      />

      <p class="gl-text-gray-500 gl-line-height-20 gl-border-0 gl-mb-0">
        {{ $options.i18n.preScanVerificationSidebarInfo }}
      </p>

      <pre-scan-verification-summary v-if="!isDefaultStatus" :status="status" />

      <pre-scan-verification-list class="gl-pt-0!" :status="status" />
    </template>
  </gl-drawer>
</template>
