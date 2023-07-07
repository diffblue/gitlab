import { s__ } from '~/locale';

export const CI_VARIABLE = 'ci_variable';

export const FILTERS = [
  {
    text: s__('ScanResultPolicy|Customized CI Variables'),
    value: CI_VARIABLE,
    tooltip: s__('ScanExecutionPolicy|Maximum number of CI-criteria is one'),
  },
];
