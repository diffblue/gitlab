import { __ } from '~/locale';
/**
 * TODO replace with actual statuses from backend
 * when backend is ready
 */
export const PRE_SCAN_VERIFICATION_STATUS = {
  DEFAULT: __('Default - Never run'),
  IN_PROGRESS: __('In progress'),
  COMPLETE: __('Complete'),
  COMPLETE_WITH_ERRORS: __('Complete with errors'),
  FAILED: __('Failed'),
  INVALIDATED: __('Invalidated'),
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
