import { s__ } from '~/locale';
import { REPORT_TYPES_DEFAULT } from 'ee/security_dashboard/store/constants';

const REPORT_TYPES_KEYS = Object.keys(REPORT_TYPES_DEFAULT);

export const SCAN_FINDING = 'scan_finding';
export const LICENSE_FINDING = 'license_finding';
export const MATCHING = s__('ScanResultPolicy|matching');
export const EXCEPT = s__('ScanResultPolicy|except');

export const LICENSE_STATES = {
  newly_detected: s__('ScanResultPolicy|Newly Detected'),
  detected: s__('ScanResultPolicy|Pre-existing'),
};

/*
  Construct a new rule object.
*/
export function securityScanBuildRule() {
  return {
    type: SCAN_FINDING,
    branches: [],
    scanners: [],
    vulnerabilities_allowed: 0,
    severity_levels: [],
    vulnerability_states: [],
  };
}

export function licenseScanBuildRule() {
  return {
    type: LICENSE_FINDING,
    branches: [],
    match_on_inclusion: true,
    license_types: [],
    license_states: [],
  };
}

/*
  Construct a new rule object for when the licenseScanningPolocies flag is on
*/
export function emptyBuildRule() {
  return {
    type: '',
  };
}

/*
  Check if scanners are valid for each rule.
*/
export function invalidScanners(rules) {
  return (
    rules
      ?.flatMap((rule) => rule.scanners)
      .some((scanner) => !REPORT_TYPES_KEYS.includes(scanner)) || false
  );
}

/*
  Returns the config for a particular rule type
*/
export const getDefaultRule = (scanType) => {
  switch (scanType) {
    case SCAN_FINDING:
      return securityScanBuildRule();
    case LICENSE_FINDING:
      return licenseScanBuildRule();
    default:
      return emptyBuildRule();
  }
};
