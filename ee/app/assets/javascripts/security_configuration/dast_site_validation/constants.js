import { s__ } from '~/locale';

export const DAST_SITE_VALIDATION_METHOD_TEXT_FILE = 'TEXT_FILE';
export const DAST_SITE_VALIDATION_METHOD_HTTP_HEADER = 'HEADER';
export const DAST_SITE_VALIDATION_METHOD_META_TAG = 'META_TAG';

export const DAST_SITE_VALIDATION_METHODS = {
  [DAST_SITE_VALIDATION_METHOD_TEXT_FILE]: {
    value: DAST_SITE_VALIDATION_METHOD_TEXT_FILE,
    text: s__('DastSiteValidation|Text file validation'),
    i18n: {
      locationStepLabel: s__('DastSiteValidation|Step 3 - Confirm text file location and validate'),
    },
  },
  [DAST_SITE_VALIDATION_METHOD_HTTP_HEADER]: {
    value: DAST_SITE_VALIDATION_METHOD_HTTP_HEADER,
    text: s__('DastSiteValidation|Header validation'),
    i18n: {
      locationStepLabel: s__('DastSiteValidation|Step 3 - Confirm header location and validate'),
    },
  },
  [DAST_SITE_VALIDATION_METHOD_META_TAG]: {
    value: DAST_SITE_VALIDATION_METHOD_META_TAG,
    text: s__('DastSiteValidation|Meta tag validation'),
    i18n: {
      locationStepLabel: s__('DastSiteValidation|Step 3 - Confirm meta tag location and validate'),
    },
  },
};

export const DAST_SITE_VALIDATION_STATUS = {
  NONE: 'NONE',
  PENDING: 'PENDING_VALIDATION',
  INPROGRESS: 'INPROGRESS_VALIDATION',
  PASSED: 'PASSED_VALIDATION',
  FAILED: 'FAILED_VALIDATION',
};

const INPROGRESS_VALIDATION_PROPS = {
  labelText: s__('DastSiteValidation|Validating...'),
  name: 'status-running',
  class: 'gl-text-blue-500',
  title: s__('DastSiteValidation|The validation is in progress. Please wait...'),
};

export const DAST_SITE_VALIDATION_STATUS_PROPS = {
  [DAST_SITE_VALIDATION_STATUS.PENDING]: INPROGRESS_VALIDATION_PROPS,
  [DAST_SITE_VALIDATION_STATUS.INPROGRESS]: INPROGRESS_VALIDATION_PROPS,
  [DAST_SITE_VALIDATION_STATUS.PASSED]: {
    labelText: s__('DastSiteValidation|Validated'),
    name: 'status-success',
    class: 'gl-text-green-500',
    title: s__(
      'DastSiteValidation|Validation succeeded. Both active and passive scans can be run against the target site.',
    ),
  },
  [DAST_SITE_VALIDATION_STATUS.FAILED]: {
    labelText: s__('DastSiteValidation|Validation failed'),
    name: 'status-failed',
    class: 'gl-text-red-500',
    title: s__('DastSiteValidation|The validation has failed. Please try again.'),
  },
};

export const DAST_SITE_VALIDATION_HTTP_HEADER_KEY = 'Gitlab-On-Demand-DAST';

export const DAST_SITE_VALIDATION_MODAL_ID = 'dast-site-validation-modal';

export const DAST_SITE_VALIDATION_REVOKE_MODAL_ID = 'dast-site-validation-revoke-modal';

export const DAST_SITE_VALIDATION_POLLING_INTERVAL = 3000;
