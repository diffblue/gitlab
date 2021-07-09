export { fromYaml } from './from_yaml';

export * from './constants';
export * from './utils';

export const DEFAULT_SCAN_EXECUTION_POLICY = `type: scan_execution_policy
name: ''
description: ''
enabled: false
rules:
  - type: pipeline
    branches:
      - main
actions:
  - scan: dast
    site_profile: ''
    scanner_profile: ''
`;
