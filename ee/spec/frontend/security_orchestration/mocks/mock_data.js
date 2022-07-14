export const mockSecretDetectionScanExecutionManifest = `---
name: Enforce DAST in every pipeline
enabled: false,
rules:
- type: pipeline
  branches:
  - main
  - release/*
  - staging
actions:
- scan: secret_detection
`;

export const mockDastAndSecretDetectionScanExecutionManifest = `---
name: Enforce DAST in every pipeline
description: This policy enforces pipeline configuration to have a job with DAST scan
enabled: true
rules:
- type: schedule
  cadence: "*/10 * * * *"
  branches:
  - main
- type: pipeline
  branches:
  - main
  - release/*
  - staging
actions:
- scan: dast
  scanner_profile: Scanner Profile
  site_profile: Site Profile
- scan: secret_detection
`;

export const mockScanExecutionManifestNoActions = `type: scan_execution_policy
name: Test Dast
description: This policy enforces pipeline configuration to have a job with DAST scan
enabled: false
rules:
  - type: pipeline
    branches:
      - main
actions: []
`;

export const mockDastScanExecutionManifest = `type: scan_execution_policy
name: Scheduled Dast/SAST scan
description: This policy enforces pipeline configuration to have a job with DAST scan
enabled: false
rules:
  - type: pipeline
    branches:
      - main
actions:
  - scan: dast
    site_profile: required_site_profile
    scanner_profile: required_scanner_profile
`;

export const mockScanExecutionManifestMultipleActions = `type: scan_execution_policy
name: Test Dast
description: This policy enforces pipeline configuration to have a job with DAST scan
enabled: false
rules:
  - type: pipeline
    branches:
      - main
actions:
  - scan: container_scanning
  - scan: secret_detection
  - scan: sast
`;

export const mockDastScanExecutionObject = {
  type: 'scan_execution_policy',
  name: 'Scheduled Dast/SAST scan',
  description: 'This policy enforces pipeline configuration to have a job with DAST scan',
  enabled: false,
  rules: [{ type: 'pipeline', branches: ['main'] }],
  actions: [
    {
      scan: 'dast',
      site_profile: 'required_site_profile',
      scanner_profile: 'required_scanner_profile',
    },
  ],
};

export const mockProjectScanExecutionPolicy = {
  __typename: 'ScanExecutionPolicy',
  name: 'Scheduled DAST/SAST scan',
  updatedAt: new Date('2021-06-07T00:00:00.000Z'),
  yaml: mockDastScanExecutionManifest,
  enabled: true,
  source: {
    __typename: 'ProjectSecurityPolicySource',
  },
};

export const mockGroupScanExecutionPolicy = {
  __typename: 'ScanExecutionPolicy',
  name: 'Group Inherited Scheduled DAST/SAST scan',
  updatedAt: new Date('2021-06-07T00:00:00.000Z'),
  yaml: mockDastScanExecutionManifest,
  enabled: false,
  source: {
    __typename: 'GroupSecurityPolicySource',
    inherited: true,
    namespace: {
      __typename: 'Namespace',
      id: '1',
      fullPath: 'parent-group-path',
      name: 'parent-group-name',
    },
  },
};

export const mockScanResultManifest = `type: scan_result_policy
name: critical vulnerability CS approvals
description: This policy enforces critical vulnerability CS approvals
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
      - the.one
`;

export const mockScanResultManifestSecond = `type: scan_result_policy
name: low vulnerability SAST approvals
description: This policy enforces low vulnerability SAST approvals
enabled: true
rules:
  - type: scan_finding
    branches:
      - main
    scanners:
      - sast
    vulnerabilities_allowed: 1
    severity_levels:
      - low
    vulnerability_states:
      - newly_detected
actions:
  - type: require_approval
    approvals_required: 1
    user_approvers:
      - the.one
`;

export const mockScanResultObject = {
  type: 'scan_result_policy',
  name: 'critical vulnerability CS approvals',
  description: 'This policy enforces critical vulnerability CS approvals',
  enabled: true,
  rules: [
    {
      type: 'scan_finding',
      branches: [],
      scanners: ['container_scanning'],
      vulnerabilities_allowed: 1,
      severity_levels: ['critical'],
      vulnerability_states: ['newly_detected'],
    },
  ],
  actions: [
    {
      type: 'require_approval',
      approvals_required: 1,
      user_approvers: ['the.one'],
    },
  ],
};

export const mockScanResultPolicy = {
  __typename: 'ScanResultPolicy',
  name: 'critical vulnerability CS approvals',
  updatedAt: new Date('2021-06-07T00:00:00.000Z'),
  yaml: mockScanResultManifest,
  enabled: false,
  userApprovers: [],
  groupApprovers: [],
};

export const mockScanResultPolicySecond = {
  __typename: 'ScanResultPolicy',
  name: 'low vulnerability sast approvals second',
  updatedAt: new Date('2021-06-07T00:00:00.000Z'),
  yaml: mockScanResultManifestSecond,
  enabled: true,
  userApprovers: [],
  groupApprovers: [],
};

export const mockScanExecutionPoliciesResponse = [
  mockProjectScanExecutionPolicy,
  mockGroupScanExecutionPolicy,
];

export const mockScanResultPoliciesResponse = [mockScanResultPolicy];

export const createRequiredApprovers = (count) => {
  const approvers = [];
  for (let i = 0; i < count; i += 1) {
    const id = i + 1;
    const approver = { webUrl: `webUrl${id}` };
    if (i % 2) {
      // eslint-disable-next-line no-underscore-dangle
      approver.__typename = 'UserCore';
      approver.name = `username${id}`;
      approver.id = `gid://gitlab/User/${id}`;
    } else {
      // eslint-disable-next-line no-underscore-dangle
      approver.__typename = 'Group';
      approver.fullPath = `grouppath${id}`;
      approver.id = `gid://gitlab/Group/${id}`;
    }
    approvers.push(approver);
  }
  return approvers;
};
