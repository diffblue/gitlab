import { s__ } from '~/locale';

export const SEVERITY = 'severity';
export const STATUS = 'status';
export const ATTRIBUTE = 'attribute';
export const AGE = 'age';

export const UNKNOWN_LICENSE = {
  value: 'unknown',
  text: s__('ScanResultPolicy|Unknown'),
};

export const AGE_TOOLTIP_MAXIMUM_REACHED = 'maximumReached';
export const AGE_TOOLTIP_NO_PREVIOUSLY_EXISTING_VULNERABILITY = 'noPreviouslyExistingVulnerability';

const AGE_TOOLTIPS = {
  [AGE_TOOLTIP_MAXIMUM_REACHED]: s__('ScanResultPolicy|Only 1 age criteria is allowed'),
  [AGE_TOOLTIP_NO_PREVIOUSLY_EXISTING_VULNERABILITY]: s__(
    'ScanResultPolicy|Age criteria can only be added for pre-existing vulnerabilities',
  ),
};

export const FILTERS = [
  {
    text: s__('ScanResultPolicy|New severity'),
    value: SEVERITY,
    tooltip: s__('ScanResultPolicy|Only 1 severity is allowed'),
  },
  {
    text: s__('ScanResultPolicy|New status'),
    value: STATUS,
    tooltip: s__('ScanResultPolicy|Only 2 status criteria are allowed'),
  },
  {
    text: s__('ScanResultPolicy|New age'),
    value: AGE,
    tooltip: AGE_TOOLTIPS,
  },
  {
    text: s__('ScanResultPolicy|New attribute'),
    value: ATTRIBUTE,
    tooltip: s__('ScanResultPolicy|Only 2 attribute criteria are allowed'),
  },
];

export const AGE_DAY = 'day';
export const AGE_WEEK = 'week';
export const AGE_MONTH = 'month';
export const AGE_YEAR = 'year';

export const AGE_INTERVALS = [
  { value: AGE_DAY, text: s__('ApprovalRule|day(s)') },
  { value: 'week', text: s__('ApprovalRule|week(s)') },
  { value: 'month', text: s__('ApprovalRule|month(s)') },
  { value: 'year', text: s__('ApprovalRule||year(s)') },
];

export const VULNERABILITY_AGE_ALLOWED_KEYS = ['value', 'interval', 'operator'];

export const FILTERS_STATUS_INDEX = FILTERS.findIndex(({ value }) => value === STATUS);

export const FIX_AVAILABLE = 'fix_available';
export const FALSE_POSITIVE = 'false_positive';

export const VULNERABILITY_ATTRIBUTES = [
  { value: FIX_AVAILABLE, text: s__('ScanResultPolicy|Fix available') },
  { value: FALSE_POSITIVE, text: s__('ScanResultPolicy|False positive') },
];
export const VULNERABILITY_ATTRIBUTE_OPERATORS = [
  { text: s__('ScanResultPolicy|Is'), value: 'true' },
  { text: s__('ScanResultPolicy|Is not'), value: 'false' },
];

export const NEWLY_DETECTED = 'newly_detected';
export const PREVIOUSLY_EXISTING = 'previously_existing';

export const NEEDS_TRIAGE_PLURAL = s__('ApprovalRule|Need triage');
export const NEEDS_TRIAGE_SINGULAR = s__('ApprovalRule|Needs triage');

export const APPROVAL_VULNERABILITY_STATE_GROUPS = {
  [NEWLY_DETECTED]: s__('ApprovalRule|New'),
  [PREVIOUSLY_EXISTING]: s__('ApprovalRule|Previously existing'),
};

export const APPROVAL_VULNERABILITY_STATES = {
  [NEWLY_DETECTED]: {
    new_needs_triage: NEEDS_TRIAGE_SINGULAR,
    new_dismissed: s__('ApprovalRule|Dismissed'),
  },
  [PREVIOUSLY_EXISTING]: {
    detected: s__('ApprovalRule|Needs triage'),
    confirmed: s__('ApprovalRule|Confirmed'),
    dismissed: s__('ApprovalRule|Dismissed'),
    resolved: s__('ApprovalRule|Resolved'),
  },
};

export const APPROVAL_VULNERABILITY_STATES_FLAT = Object.values(
  APPROVAL_VULNERABILITY_STATES,
).reduce((acc, states) => ({ ...acc, ...states }), {});
