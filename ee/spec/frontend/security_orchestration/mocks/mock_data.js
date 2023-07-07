export const unsupportedManifest = `---
name: This policy has an unsupported attribute
enabled: false
UNSUPPORTED: ATTRIBUTE
rules:
- type: pipeline
  branches:
  - main
actions:
- scan: sast
`;

export const collidingKeys = `---
name: This policy has colliding keys
description: This policy has colliding keys
enabled: true
rules:
  - type: scan_finding
    branches: []
    branch_type: protected
    scanners: []
    vulnerabilities_allowed: 0
    severity_levels: []
    vulnerability_states: []
actions:
  - type: require_approval
    approvals_required: 1
`;

export const unsupportedManifestObject = {
  name: 'This policy has an unsupported attribute',
  enabled: false,
  UNSUPPORTED: 'ATTRIBUTE',
  rules: [
    {
      type: 'pipeline',
      branches: ['main'],
    },
  ],
  actions: [
    {
      scan: 'sast',
    },
  ],
};

export const RUNNER_TAG_LIST_MOCK = [
  {
    id: 'gid://gitlab/Ci::Runner/1',
    tagList: ['macos', 'linux', 'docker'],
  },
  {
    id: 'gid://gitlab/Ci::Runner/2',
    tagList: ['backup', 'linux', 'development'],
  },
];
