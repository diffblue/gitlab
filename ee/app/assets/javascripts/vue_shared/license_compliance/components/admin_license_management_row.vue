<script>
import {
  GlTooltipDirective,
  GlDropdown,
  GlDropdownItem,
  GlLoadingIcon,
  GlIcon,
  GlButton,
  GlModalDirective,
} from '@gitlab/ui';
import { mapActions } from 'vuex';
import { LICENSE_MANAGEMENT } from 'ee/vue_shared/license_compliance/store/constants';
import { getIssueStatusFromLicenseStatus } from 'ee/vue_shared/license_compliance/store/utils';
import { s__ } from '~/locale';
import IssueStatusIcon from '~/ci/reports/components/issue_status_icon.vue';

import { LICENSE_APPROVAL_STATUS, LICENSE_APPROVAL_ACTION } from '../constants';

const visibleClass = 'visible';
const invisibleClass = 'invisible';

export default {
  name: 'AdminLicenseManagementRow',
  components: {
    GlDropdown,
    GlDropdownItem,
    GlButton,
    GlLoadingIcon,
    GlIcon,
    IssueStatusIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModal: GlModalDirective,
  },

  props: {
    license: {
      type: Object,
      required: true,
      validator: (license) =>
        Boolean(license.name) &&
        Object.values(LICENSE_APPROVAL_STATUS).includes(license.approvalStatus),
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  LICENSE_APPROVAL_STATUS,
  LICENSE_APPROVAL_ACTION,
  [LICENSE_APPROVAL_ACTION.ALLOW]: s__('LicenseCompliance|Allow'),
  [LICENSE_APPROVAL_ACTION.DENY]: s__('LicenseCompliance|Deny'),
  [LICENSE_APPROVAL_STATUS.ALLOWED]: s__('LicenseCompliance|Allowed'),
  [LICENSE_APPROVAL_STATUS.DENIED]: s__('LicenseCompliance|Denied'),
  computed: {
    allowedIconClass() {
      return this.license.approvalStatus === LICENSE_APPROVAL_STATUS.ALLOWED
        ? visibleClass
        : invisibleClass;
    },
    deniedIconClass() {
      return this.license.approvalStatus === LICENSE_APPROVAL_STATUS.DENIED
        ? visibleClass
        : invisibleClass;
    },
    status() {
      return getIssueStatusFromLicenseStatus(this.license.approvalStatus);
    },
    dropdownText() {
      return this.$options[this.license.approvalStatus];
    },
  },
  methods: {
    ...mapActions(LICENSE_MANAGEMENT, ['setLicenseInModal', 'allowLicense', 'denyLicense']),
  },
};
</script>
<template>
  <div
    class="gl-display-flex gl-align-items-center"
    data-qa-selector="admin_license_compliance_container"
    data-testid="admin-license-compliance-row"
  >
    <issue-status-icon :status="status" class="gl-display-flex gl-mr-3" />
    <span class="gl-flex-grow-1" data-testid="license-name">{{ license.name }}</span>
    <div class="gl-display-flex">
      <gl-loading-icon
        v-if="loading"
        size="sm"
        class="gl-display-flex gl-align-items-center gl-mr-3"
      />
      <gl-dropdown
        :text="dropdownText"
        :disabled="loading"
        toggle-class="gl-display-flex gl-justify-content-space-between gl-align-items-center"
        right
      >
        <gl-dropdown-item @click="allowLicense(license)">
          <gl-icon :class="allowedIconClass" name="mobile-issue-close" />
          {{ $options[$options.LICENSE_APPROVAL_ACTION.ALLOW] }}
        </gl-dropdown-item>
        <gl-dropdown-item @click="denyLicense(license)">
          <gl-icon :class="deniedIconClass" name="mobile-issue-close" />
          {{ $options[$options.LICENSE_APPROVAL_ACTION.DENY] }}
        </gl-dropdown-item>
      </gl-dropdown>

      <gl-button
        v-gl-tooltip
        v-gl-modal.modal-license-delete-confirmation
        :title="__('Remove license')"
        :aria-label="__('Remove license')"
        :disabled="loading"
        icon="remove"
        class="gl-ml-3"
        category="tertiary"
        @click="setLicenseInModal(license)"
      />
    </div>
  </div>
</template>
