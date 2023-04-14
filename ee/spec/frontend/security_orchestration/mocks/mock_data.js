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
