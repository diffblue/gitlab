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
  [STATUS]: s__('ScanResultPolicy|Maximum number of status-criteria is one'),
};

export const FILTER_POLICY_PROPERTY_MAP = {
  [STATUS]: 'vulnerability_states',
  [SEVERITY]: 'severity_levels',
};
