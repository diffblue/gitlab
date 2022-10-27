<script>
import PreScanVerificationStatus from 'ee/security_configuration/dast_pre_scan_verification/components/pre_scan_verification_status.vue';
import PreScanVerificationSidebar from 'ee/security_configuration/dast_pre_scan_verification/components/pre_scan_verification_sidebar.vue';

export default {
  name: 'PreScanVerificationConfigurator',
  components: {
    PreScanVerificationStatus,
    PreScanVerificationSidebar,
  },
  data() {
    return {
      isSidebarOpen: false,
    };
  },
  methods: {
    openSidebar() {
      this.isSidebarOpen = true;
    },
    closeSidebar() {
      this.isSidebarOpen = false;
    },
  },
};
</script>

<template>
  <div>
    <slot name="action-trigger" :open-sidebar="openSidebar">
      <pre-scan-verification-status
        pipeline-id="2343434"
        pipeline-created-at="2022-09-23 11:19:49 UTC"
        pipeline-path="test-path"
        @select-results="openSidebar"
      />
    </slot>

    <pre-scan-verification-sidebar :is-open="isSidebarOpen" @close="closeSidebar" />
  </div>
</template>
