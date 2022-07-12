import { s__ } from '~/locale';

export { fromYaml } from './from_yaml';
export { toYaml } from './to_yaml';
export { buildRule, invalidScanners } from './rules';
export { approversOutOfSync } from './actions';
export * from './humanize';

export const DEFAULT_SCAN_RESULT_POLICY = `type: scan_result_policy
name: ''
description: ''
enabled: true
rules:
  - type: scan_finding
    branches: []
    scanners: []
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

export const APPROVAL_VULNERABILITY_STATES = {
  newly_detected: s__('ApprovalRule|Newly detected'),
  detected: s__('ApprovalRule|Previously detected'),
  confirmed: s__('ApprovalRule|Confirmed'),
  dismissed: s__('ApprovalRule|Dismissed'),
  resolved: s__('ApprovalRule|Resolved'),
};
