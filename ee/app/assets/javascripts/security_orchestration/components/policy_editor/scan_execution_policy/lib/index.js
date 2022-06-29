export { fromYaml } from './from_yaml';
export { toYaml } from './to_yaml';
export * from './humanize';

export const DEFAULT_SCAN_EXECUTION_POLICY = `type: scan_execution_policy
name: # name is mandatory
description: ''
enabled: true
rules:
  - type: pipeline
    branches:
      - # branch is mandatory
actions:
  - scan: dast
    site_profile: ''
    scanner_profile: ''
`;
