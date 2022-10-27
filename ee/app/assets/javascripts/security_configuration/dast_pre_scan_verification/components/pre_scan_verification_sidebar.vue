<script>
import { GlDrawer } from '@gitlab/ui';
import { s__ } from '~/locale';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { getContentWrapperHeight } from 'ee/security_orchestration/utils';

export default {
  DRAWER_Z_INDEX,
  i18n: {
    preScanVerificationSidebarHeader: s__('PreScanVerification|Pre-scan verification'),
    preScanVerificationSidebarInfo: s__(
      'PreScanVerification|Test your configuration and identify potential errors before running a full scan.',
    ),
  },
  name: 'PreScanVerificationSidebar',
  components: {
    GlDrawer,
  },
  props: {
    isOpen: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
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
    :open="isOpen"
    :z-index="$options.DRAWER_Z_INDEX"
    @close="$emit('close')"
  >
    <template #title>
      <h4 data-testid="sidebar-header" class="gl-font-size-h2 gl-my-0">
        {{ $options.i18n.preScanVerificationSidebarHeader }}
      </h4>
    </template>
    <template #default>
      <p class="gl-text-gray-500 gl-line-height-20">
        {{ $options.i18n.preScanVerificationSidebarInfo }}
      </p>
    </template>
  </gl-drawer>
</template>
