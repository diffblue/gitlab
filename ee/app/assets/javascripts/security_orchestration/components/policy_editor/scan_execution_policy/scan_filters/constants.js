import { s__ } from '~/locale';

export const RUNNER_TAGS = 'runner_tags';

export const CI_VARIABLE = 'ci_variable';

export const FILTERS = [
  {
    text: s__('ScanExecutionPolicy|Runner tags'),
    value: RUNNER_TAGS,
    tooltip: s__('ScanExecutionPolicy|Maximum number of runner tags-criteria is one'),
  },
  {
    text: s__('ScanResultPolicy|Customized CI Variables'),
    value: CI_VARIABLE,
    tooltip: s__('ScanExecutionPolicy|Maximum number of CI-criteria is one'),
  },
];
