import { s__ } from '~/locale';

export { fromYaml } from './from_yaml';
export { toYaml } from './to_yaml';
export {
  securityScanBuildRule,
  emptyBuildRule,
  getDefaultRule,
  invalidScanners,
  SCAN_FINDING,
  LICENSE_FINDING,
} from './rules';
export { approversOutOfSync, APPROVER_TYPE_DICT, APPROVER_TYPE_LIST_ITEMS } from './actions';
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

// TODO incorporate any action changes from DEFAULT_SCAN_RESULT_POLICY when removing
export const DEFAULT_SCAN_RESULT_POLICY_V2 = `type: scan_result_policy
name: ''
description: ''
enabled: true
rules:
  - type: ''
actions:
  - type: require_approval
    approvals_required: 1
    user_approvers: []
`;

// TODO incorporate any rule changes from DEFAULT_SCAN_RESULT_POLICY when removing
export const DEFAULT_SCAN_RESULT_POLICY_V3 = `type: scan_result_policy
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
`;

// TODO use this after both License Approval Policies and Role Based Approvals are removed
export const DEFAULT_SCAN_RESULT_POLICY_V4 = `type: scan_result_policy
name: ''
description: ''
enabled: true
rules:
  - type: ''
actions:
  - type: require_approval
    approvals_required: 1
`;

export const APPROVAL_VULNERABILITY_STATES = {
  newly_detected: s__('ApprovalRule|Newly detected'),
  detected: s__('ApprovalRule|Previously detected'),
  confirmed: s__('ApprovalRule|Confirmed'),
  dismissed: s__('ApprovalRule|Dismissed'),
  resolved: s__('ApprovalRule|Resolved'),
};
