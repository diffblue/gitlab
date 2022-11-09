import { s__, __ } from '~/locale';
/**
 * TODO replace with actual statuses from backend
 * when backend is ready
 */
export const PRE_SCAN_VERIFICATION_STATUS = {
  DEFAULT: 'default',
  IN_PROGRESS: 'running',
  COMPLETE: 'complete',
  COMPLETE_WITH_ERRORS: 'complete_with_errors',
  FAILED: 'failed',
  INVALIDATED: 'invalidated',
};

export const PRE_SCAN_VERIFICATION_STATUS_LABEL_MAP = {
  [PRE_SCAN_VERIFICATION_STATUS.DEFAULT]: __('Default - Never run'),
  [PRE_SCAN_VERIFICATION_STATUS.IN_PROGRESS]: __('Running'),
  [PRE_SCAN_VERIFICATION_STATUS.COMPLETE]: __('Complete'),
  [PRE_SCAN_VERIFICATION_STATUS.COMPLETE_WITH_ERRORS]: __('Complete with errors'),
  [PRE_SCAN_VERIFICATION_STATUS.FAILED]: __('Failed'),
  [PRE_SCAN_VERIFICATION_STATUS.INVALIDATED]: __('Invalidated'),
};

export const STATUS_STYLE_MAP = {
  [PRE_SCAN_VERIFICATION_STATUS.DEFAULT]: {
    icon: 'review-checkmark',
    variant: 'neutral',
  },
  [PRE_SCAN_VERIFICATION_STATUS.COMPLETE]: {
    icon: 'check-sm',
    variant: 'success',
  },
  [PRE_SCAN_VERIFICATION_STATUS.COMPLETE_WITH_ERRORS]: {
    icon: 'status_warning_borderless',
    variant: 'warning',
  },
  [PRE_SCAN_VERIFICATION_STATUS.FAILED]: {
    icon: 'status_failed',
    variant: 'danger',
  },
  [PRE_SCAN_VERIFICATION_STATUS.INVALIDATED]: {
    icon: 'status_failed',
    variant: 'danger',
  },
};

export const DEFAULT_STYLING = STATUS_STYLE_MAP[PRE_SCAN_VERIFICATION_STATUS.DEFAULT];

export const SUMMARY_STATUS_STYLE_MAP = {
  [PRE_SCAN_VERIFICATION_STATUS.IN_PROGRESS]: {
    icon: 'status_running',
    iconColor: 'gl-text-blue-500',
    borderColor: 'border-color: #428fdc',
  },
  [PRE_SCAN_VERIFICATION_STATUS.COMPLETE]: {
    icon: 'check-circle',
    iconColor: 'gl-text-green-500',
    borderColor: 'border-color: #108548',
  },
  [PRE_SCAN_VERIFICATION_STATUS.COMPLETE_WITH_ERRORS]: {
    icon: 'status_warning',
    iconColor: 'gl-text-orange-500',
    borderColor: 'border-color: #c17d10',
  },
  [PRE_SCAN_VERIFICATION_STATUS.FAILED]: {
    icon: 'status_failed',
    iconColor: 'gl-text-red-500',
    borderColor: 'border-color: #ec5941',
  },
  [PRE_SCAN_VERIFICATION_STATUS.INVALIDATED]: {
    icon: 'status_failed',
    iconColor: 'gl-text-red-500',
    borderColor: 'border-color: #ec5941',
  },
};

export const STATUS_LABEL_MAP = {
  [PRE_SCAN_VERIFICATION_STATUS.DEFAULT]: __('default'),
  [PRE_SCAN_VERIFICATION_STATUS.IN_PROGRESS]: __('running'),
  [PRE_SCAN_VERIFICATION_STATUS.COMPLETE]: __('complete'),
  [PRE_SCAN_VERIFICATION_STATUS.COMPLETE_WITH_ERRORS]: __('complete'),
  [PRE_SCAN_VERIFICATION_STATUS.FAILED]: __('failed'),
  [PRE_SCAN_VERIFICATION_STATUS.INVALIDATED]: __('invalidated'),
};

export const DEFAULT_STYLING_SUMMARY_STYLING =
  SUMMARY_STATUS_STYLE_MAP[PRE_SCAN_VERIFICATION_STATUS.IN_PROGRESS];

export const PRE_SCAN_VERIFICATION_STEPS = [
  {
    header: s__('PreScanVerification|Connection'),
    text: s__('PreScanVerification|Attempts to find and connect to the scan target'),
  },
  {
    header: s__('PreScanVerification|Authentication'),
    text: s__('PreScanVerification|Attempts to authenticate with the scan target'),
  },
  {
    header: s__('PreScanVerification|Target exploration'),
    text: s__(
      'PreScanVerification|Attempts to follow internal links and crawl 3 pages without errors',
    ),
  },
];

export const PRE_SCAN_VERIFICATION_STEPS_LAST_INDEX = PRE_SCAN_VERIFICATION_STEPS.length - 1;

/**
 * Translations
 */

export const PRE_SCAN_VERIFICATION_LIST_TRANSLATIONS = {
  preScanVerificationListHeader: s__('PreScanVerification|Verification checks'),
  preScanVerificationListTooltip: s__(
    'PreScanVerification|Verification checks are determined by a scan’s configuration details. Changing configuration details may alter or reset the verification checks and their status.',
  ),
  preScanVerificationButtonDefault: s__('PreScanVerification|Save and run verification'),
  preScanVerificationButtonInProgress: s__('PreScanVerification|Cancel pre-scan verification'),
  preScanVerificationButtonTooltip: s__(
    'PreScanVerification|You must complete the scan configuration form before running pre-scan verification',
  ),
};

export const PRE_SCAN_VERIFICATION_ALERT_TRANSLATIONS = {
  preScanVerificationDefaultTitle: s__(
    'PreScanVerification|The pre-scan verification status was reset for this scan',
  ),
  preScanVerificationDefaultText: s__(
    'PreScanVerification|The last pre-scan verification job is no longer valid because this scan’s configuration has changed.',
  ),
};

export const ALERT_VARIANT_STATUS_MAP = {
  [PRE_SCAN_VERIFICATION_STATUS.DEFAULT]: 'tip',
  [PRE_SCAN_VERIFICATION_STATUS.COMPLETE]: 'success',
  [PRE_SCAN_VERIFICATION_STATUS.COMPLETE_WITH_ERRORS]: 'warning',
  [PRE_SCAN_VERIFICATION_STATUS.FAILED]: 'danger',
  [PRE_SCAN_VERIFICATION_STATUS.INVALIDATED]: 'danger',
};
