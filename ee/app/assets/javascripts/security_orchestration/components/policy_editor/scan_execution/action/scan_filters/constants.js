import { s__ } from '~/locale';

export const CI_VARIABLE = 'ci_variable';

export const FILTERS = [
  {
    text: s__('ScanResultPolicy|Customized CI Variables'),
    value: CI_VARIABLE,
    tooltip: s__('ScanExecutionPolicy|Maximum number of CI-criteria is one'),
  },
];

export const DAST_PROFILE_I18N = {
  selectedScannerProfilePlaceholder: s__('ScanExecutionPolicy|Select scanner profile'),
  selectedSiteProfilePlaceholder: s__('ScanExecutionPolicy|Select site profile'),
  scanCreate: s__('ScanExecutionPolicy|Create new scan profile'),
  scanLabel: s__('ScanExecutionPolicy|DAST scan profiles'),
  siteCreate: s__('ScanExecutionPolicy|Create new site profile'),
  siteLabel: s__('ScanExecutionPolicy|DAST site profiles'),
};
