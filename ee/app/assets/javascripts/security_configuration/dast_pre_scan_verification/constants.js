import { __ } from '~/locale';
/**
 * TODO replace with actual statuses from backend
 * when backend is ready
 */
export const PRE_SCAN_VERIFICATION_STATUS = {
  DEFAULT: __('Default - Never run'),
  IN_PROGRESS: __('running'),
  COMPLETE: __('complete'),
  COMPLETE_WITH_ERRORS: __('complete_with_errors'),
  FAILED: __('failed'),
  INVALIDATED: __('invalidated'),
};

export const STATUS_STYLE_MAP = {
  [PRE_SCAN_VERIFICATION_STATUS.DEFAULT]: {
    icon: 'review-checkmark',
    bgColor: 'gl-bg-gray-100',
    iconColor: 'gl-text-gray-500',
  },
  [PRE_SCAN_VERIFICATION_STATUS.COMPLETE]: {
    icon: 'check-sm',
    bgColor: 'gl-bg-green-100',
    iconColor: 'gl-text-green-500',
  },
  [PRE_SCAN_VERIFICATION_STATUS.COMPLETE_WITH_ERRORS]: {
    icon: 'status_warning_borderless',
    bgColor: 'gl-bg-orange-100',
    iconColor: 'gl-text-orange-500',
  },
  [PRE_SCAN_VERIFICATION_STATUS.FAILED]: {
    icon: 'status_failed',
    bgColor: 'gl-bg-red-100',
    iconColor: 'gl-text-red-500',
  },
  [PRE_SCAN_VERIFICATION_STATUS.INVALIDATED]: {
    icon: 'status_failed',
    bgColor: 'gl-bg-red-100',
    iconColor: 'gl-text-red-500',
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
  [PRE_SCAN_VERIFICATION_STATUS.INVALIDATED]: __('failed'),
};

export const DEFAULT_STYLING_SUMMARY_STYLING =
  SUMMARY_STATUS_STYLE_MAP[PRE_SCAN_VERIFICATION_STATUS.IN_PROGRESS];
