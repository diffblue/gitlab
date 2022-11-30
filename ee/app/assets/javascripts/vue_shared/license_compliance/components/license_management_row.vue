<script>
import {
  getIssueStatusFromLicenseStatus,
  getStatusTranslationsFromLicenseStatus,
} from 'ee/vue_shared/license_compliance/store/utils';
import IssueStatusIcon from '~/ci/reports/components/issue_status_icon.vue';

export default {
  name: 'LicenseManagementRow',
  components: {
    IssueStatusIcon,
  },
  props: {
    license: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    iconStatus() {
      return getIssueStatusFromLicenseStatus(this.license.approvalStatus);
    },
    textStatus() {
      return getStatusTranslationsFromLicenseStatus(this.license.approvalStatus);
    },
  },
};
</script>

<template>
  <div class="gl-responsive-table-row flex-md-column align-items-md-stretch p-0">
    <div class="d-md-flex align-items-center js-license-row">
      <!-- Name-->
      <div class="table-section section-30 section-wrap pr-md-3">
        <div class="table-mobile-header" role="rowheader">
          {{ s__('Licenses|Name') }}
        </div>
        <div class="table-mobile-content name">
          {{ license.name }}
        </div>
      </div>

      <!-- Policy -->
      <div class="table-section section-70 section-wrap pr-md-3">
        <div class="table-mobile-header" role="rowheader">{{ s__('Licenses|Policy') }}</div>
        <div
          class="table-mobile-content text-capitalize d-flex align-items-center justify-content-end justify-content-md-start status"
        >
          <issue-status-icon :status="iconStatus" />
          {{ textStatus }}
        </div>
      </div>
    </div>
  </div>
</template>
