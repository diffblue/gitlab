import { s__ } from '~/locale';

export const SEVERITY = 'severity';
export const STATUS = 'status';

export const FILTERS = [
  {
    text: s__('ScanResultPolicy|New severity'),
    value: SEVERITY,
  },
  {
    text: s__('ScanResultPolicy|New status'),
    value: STATUS,
  },
];

export const FILTERS_STATUS_INDEX = FILTERS.findIndex(({ value }) => value === STATUS);

export const TOOLTIPS = {
  [SEVERITY]: s__('ScanResultPolicy|Maximum number of severity-criteria is one'),
  [STATUS]: s__('ScanResultPolicy|Maximum number of status-criteria is two'),
};

export const FILTER_POLICY_PROPERTY_MAP = {
  [STATUS]: 'vulnerability_states',
  [SEVERITY]: 'severity_levels',
};

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
