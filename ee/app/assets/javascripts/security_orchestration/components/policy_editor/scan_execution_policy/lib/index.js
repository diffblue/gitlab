export { createPolicyObject, fromYaml } from './from_yaml';
export { toYaml } from './to_yaml';
export * from './humanize';
export * from './rules';
export * from './cron';
export * from './actions';

export const DEFAULT_SCAN_EXECUTION_POLICY = `type: scan_execution_policy
name: ''
description: ''
enabled: true
rules:
  - type: pipeline
    branches:
      - '*'
actions:
  - scan: dast
    site_profile: ''
    scanner_profile: ''
    tags: []
`;
