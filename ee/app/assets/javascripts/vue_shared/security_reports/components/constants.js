import { s__ } from '~/locale';

export const SEVERITY_CLASS_NAME_MAP = {
  critical: 'gl-text-red-800',
  high: 'gl-text-red-600',
  medium: 'gl-text-orange-400',
  low: 'gl-text-orange-300',
  info: 'gl-text-blue-400',
  unknown: 'gl-text-gray-400',
};

export const SEVERITY_TOOLTIP_TITLE_MAP = {
  unknown: s__(
    `SecurityReports|Sometimes a scanner can't determine a finding's severity. Those findings may still be a potential source of risk though. Please review these manually.`,
  ),
};

export const VULNERABILITY_MODAL_ID = 'modal-mrwidget-security-issue';
export const EMPTY_BODY_MESSAGE = '<Message body is not provided>';
