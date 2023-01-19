export const unsupportedManifest = `---
name: This policy has an unsupported attribute
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
