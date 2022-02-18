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
