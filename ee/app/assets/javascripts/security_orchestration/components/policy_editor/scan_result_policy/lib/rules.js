import { REPORT_TYPES_DEFAULT } from 'ee/security_dashboard/store/constants';

const REPORT_TYPES_KEYS = Object.keys(REPORT_TYPES_DEFAULT);

/*
  Construct a new rule object.
*/
export function buildRule() {
  return {
    type: 'scan_finding',
    branches: [],
    scanners: [],
    vulnerabilities_allowed: 0,
    severity_levels: [],
    vulnerability_states: [],
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
