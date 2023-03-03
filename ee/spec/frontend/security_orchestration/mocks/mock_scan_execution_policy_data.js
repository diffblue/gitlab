import { unsupportedManifest, unsupportedManifestObject } from './mock_data';

export const mockUnsupportedAttributeScanExecutionPolicy = {
  __typename: 'ScanExecutionPolicy',
  name: unsupportedManifestObject.name,
  updatedAt: new Date('2021-06-07T00:00:00.000Z'),
  yaml: unsupportedManifest,
  enabled: false,
  source: {
    __typename: 'ProjectSecurityPolicySource',
  },
};

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
    tags: []
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
      tags: [],
    },
  ],
};

export const mockProjectScanExecutionPolicy = {
  __typename: 'ScanExecutionPolicy',
  name: mockDastScanExecutionObject.name,
  updatedAt: new Date('2021-06-07T00:00:00.000Z'),
  yaml: mockDastScanExecutionManifest,
  enabled: true,
  source: {
    __typename: 'ProjectSecurityPolicySource',
    project: {
      fullPath: 'project/path',
    },
  },
};

export const mockGroupScanExecutionPolicy = {
  __typename: 'ScanExecutionPolicy',
  name: mockDastScanExecutionObject.name,
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

export const mockScanExecutionPoliciesResponse = [
  mockProjectScanExecutionPolicy,
  mockGroupScanExecutionPolicy,
];

export const mockSecretDetectionScanExecutionManifest = `---
name: Enforce DAST in every pipeline
enabled: false
rules:
- type: pipeline
  branches:
  - main
  - release/*
  - staging
actions:
- scan: secret_detection
`;

export const mockInvalidYamlCadenceValue = `---
name: Enforce DAST in every pipeline
description: This policy enforces pipeline configuration to have a job with DAST scan
enabled: true
rules:
- type: schedule
  cadence: */10 * * * *
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

export const mockNoActionsScanExecutionManifest = `type: scan_execution_policy
name: Test Dast
description: This policy enforces pipeline configuration to have a job with DAST scan
enabled: false
rules:
  - type: pipeline
    branches:
      - main
actions: []
`;

export const mockMultipleActionsScanExecutionManifest = `type: scan_execution_policy
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

export const mockInvalidCadenceScanExecutionObject = {
  name: 'This policy has an invalid cadence',
  rules: [
    {
      type: 'pipeline',
      branches: ['main'],
    },
    {
      type: 'schedule',
      branches: ['main'],
      cadence: '0 0 * * INVALID',
    },
    {
      type: 'schedule',
      branches: ['main'],
      cadence: '0 0 * * *',
    },
  ],
  actions: [
    {
      scan: 'sast',
    },
  ],
};
