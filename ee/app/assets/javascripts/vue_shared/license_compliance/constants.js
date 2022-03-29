import { __, s__ } from '~/locale';

import { STATUS_FAILED, STATUS_NEUTRAL, STATUS_SUCCESS } from '~/reports/constants';

/*
 * Legacy endpoint still returns 'approved' & 'blacklisted'
 * even though we adopted 'allowed' & 'denied' in the UI
 */
export const LICENSE_APPROVAL_STATUS = {
  ALLOWED: gon?.features?.lcRemoveLegacyApprovalStatus ? 'allowed' : 'approved',
  DENIED: gon?.features?.lcRemoveLegacyApprovalStatus ? 'denied' : 'blacklisted',
};

/*
 * New project licenses endpoint returns 'allowed' & 'denied'
 */
export const LICENSE_APPROVAL_CLASSIFICATION = {
  ALLOWED: 'allowed',
  DENIED: 'denied',
};

export const LICENSE_APPROVAL_ACTION = {
  ALLOW: 'allow',
  DENY: 'deny',
};

export const REPORT_GROUPS = [
  {
    name: s__('LicenseManagement|Denied'),
    description: __("Out-of-compliance with this project's policies and should be removed"),
    status: STATUS_FAILED,
  },
  {
    name: s__('LicenseManagement|Uncategorized'),
    description: __('No policy matches this license'),
    status: STATUS_NEUTRAL,
  },
  {
    name: s__('LicenseManagement|Allowed'),
    description: __('Acceptable for use in this project'),
    status: STATUS_SUCCESS,
  },
];

export const LICENSE_LINK_TELEMETRY_EVENT =
  'users_clicking_license_testing_visiting_external_website';
