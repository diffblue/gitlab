export { fromYaml } from './from_yaml';
export { toYaml } from './to_yaml';
export { buildRule } from './rules';
export * from './humanize';

export const DEFAULT_SCAN_RESULT_POLICY = `type: scan_result_policy
name: ''
description: ''
enabled: false
rules:
  - type: scan_finding
    branches:
      - main
    scanners:
      - container_scanning
    vulnerabilities_allowed: 0
    severity_levels:
      - critical
    vulnerability_states:
      - newly_detected
actions:
  - type: require_approval
    approvals_required: 1
    user_approvers: []
`;
