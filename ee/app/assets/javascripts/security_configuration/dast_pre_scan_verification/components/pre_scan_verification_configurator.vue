<script>
import PreScanVerificationStatus from 'ee/security_configuration/dast_pre_scan_verification/components/pre_scan_verification_status.vue';
import PreScanVerificationSidebar from 'ee/security_configuration/dast_pre_scan_verification/components/pre_scan_verification_sidebar.vue';
import { PRE_SCAN_VERIFICATION_STATUS } from '../constants';

export default {
  name: 'PreScanVerificationConfigurator',
  components: {
    PreScanVerificationStatus,
    PreScanVerificationSidebar,
  },
  props: {
    open: {
      type: Boolean,
      required: false,
      default: false,
    },
    showTrigger: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  data() {
    return {
      isSidebarOpen: false,
      status: PRE_SCAN_VERIFICATION_STATUS.DEFAULT,
      showAlert: false,
    };
  },
  watch: {
    open(newVal) {
      if (!newVal) {
        this.closeSidebar();
      }
    },
  },
  methods: {
    dismissAlert() {
      this.showAlert = false;
    },
    openSidebar() {
      this.isSidebarOpen = false;

      this.$nextTick(() => {
        this.isSidebarOpen = true;
        this.$emit('open-drawer');
      });
    },
    closeSidebar() {
      this.isSidebarOpen = false;
    },
  },
};
</script>

<template>
  <div>
    <pre-scan-verification-status
      v-if="showTrigger"
      :status="status"
      pipeline-id="2343434"
      pipeline-created-at="2022-09-23 11:19:49 UTC"
      pipeline-path="test-path"
      @select-results="openSidebar"
    />

    <pre-scan-verification-sidebar
      :open="isSidebarOpen"
      :show-alert="showAlert"
      :status="status"
      @close="closeSidebar"
      @dismiss-alert="dismissAlert"
    />
  </div>
</template>
