import { fromYaml } from 'ee/security_orchestration/components/policy_editor/scan_result_policy/lib';
import { unsupportedManifest } from 'ee_jest/security_orchestration/mocks/mock_data';

const validManifest = `type: scan_result_policy
name: critical vulnerability CS approvals
description: critical severity level only for container scanning
enabled: true
rules:
  - type: scan_finding
    branches: []
    scanners:
      - container_scanning
    vulnerabilities_allowed: 1
    severity_levels:
      - critical
    vulnerability_states:
      - newly_detected
actions:
  - type: require_approval
    approvals_required: 1
    user_approvers:
      - o.lecia.conner
    group_approvers_ids:
      - 343
`;

const invalidPrimaryKeys = `type: scan_result_policy
name: critical vulnerability CS approvals
description: critical severity level only for container scanning
invalidEnabledKey: false
rules:
  - type: scan_finding
    branches: []
    scanners:
      - container_scanning
    vulnerabilities_allowed: 1
    severity_levels:
      - critical
    vulnerability_states:
      - newly_detected
actions:
  - type: require_approval
    approvals_required: 1
    user_approvers:
      - o.lecia.conner
    group_approvers_ids:
      - 343
`;
const invalidRuleKeys = `type: scan_result_policy
name: critical vulnerability CS approvals
description: critical severity level only for container scanning
enabled: true
rules:
  - type: scan_finding
    brunch: []
    scanners:
      - container_scanning
    vulnerabilities_allowed: 1
    severity_levels:
      - critical
    vulnerability_states:
      - newly_detected
actions:
  - type: require_approval
    approvals_required: 1
    user_approvers:
      - o.lecia.conner
    group_approvers_ids:
      - 343
`;

const invalidActionKeys = `type: scan_result_policy
name: critical vulnerability CS approvals
description: critical severity level only for container scanning
enabled: true
rules:
  - type: scan_finding
    branches: []
    scanners:
      - container_scanning
    vulnerabilities_allowed: 1
    severity_levels:
      - critical
    vulnerability_states:
      - newly_detected
actions:
  - type: require_approval
    approvals_required: 1
    favorite_approvers:
      - o.lecia.conner
    group_approvers_ids:
      - 343
`;

describe('fromYaml', () => {
  it('returns policy as json with not error', () => {
    expect(fromYaml(validManifest)).toStrictEqual({
      actions: [
        {
          approvals_required: 1,
          group_approvers_ids: [343],
          type: 'require_approval',
          user_approvers: ['o.lecia.conner'],
        },
      ],
      description: 'critical severity level only for container scanning',
      enabled: true,
      name: 'critical vulnerability CS approvals',
      rules: [
        {
          branches: [],
          scanners: ['container_scanning'],
          severity_levels: ['critical'],
          type: 'scan_finding',
          vulnerabilities_allowed: 1,
          vulnerability_states: ['newly_detected'],
        },
      ],
      type: 'scan_result_policy',
    });
  });

  it.each([invalidPrimaryKeys, invalidRuleKeys, invalidActionKeys])(
    'returns hash with error set to true',
    ({ invalidManifest }) => {
      expect(fromYaml(invalidManifest)).toStrictEqual({ error: true });
    },
  );

  it('returns the error object if there is an error', () => {
    expect(fromYaml(unsupportedManifest)).toStrictEqual({ error: true });
  });
});
