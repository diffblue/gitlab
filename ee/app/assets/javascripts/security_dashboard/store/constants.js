import { s__ } from '~/locale';

export const DETECTION_METHODS = [
  s__('Vulnerability|GitLab Security Report'),
  s__('Vulnerability|External Security Report'),
  s__('Vulnerability|Bug Bounty'),
  s__('Vulnerability|Code Review'),
  s__('Vulnerability|Security Audit'),
];

export const SEVERITY_LEVELS = {
  critical: s__('severity|Critical'),
  high: s__('severity|High'),
  medium: s__('severity|Medium'),
  low: s__('severity|Low'),
  unknown: s__('severity|Unknown'),
  info: s__('severity|Info'),
};

// The GraphQL type (`VulnerabilitySeverity`) for severities is an enum with uppercase values
export const SEVERITY_LEVELS_GRAPHQL = Object.keys(SEVERITY_LEVELS).map((k) => k.toUpperCase());

export const REPORT_TYPES_DEFAULT = {
  api_fuzzing: s__('ciReport|API Fuzzing'),
  container_scanning: s__('ciReport|Container Scanning'),
  coverage_fuzzing: s__('ciReport|Coverage Fuzzing'),
  dast: s__('ciReport|DAST'),
  dependency_scanning: s__('ciReport|Dependency Scanning'),
  sast: s__('ciReport|SAST'),
  secret_detection: s__('ciReport|Secret Detection'),
};

export const REPORT_TYPES_WITH_CLUSTER_IMAGE = {
  ...REPORT_TYPES_DEFAULT,
  cluster_image_scanning: s__('ciReport|Cluster Image Scanning'),
};

export const REPORT_TYPES_WITH_MANUALLY_ADDED = {
  ...REPORT_TYPES_DEFAULT,
  generic: s__('ciReport|Manually added'),
};

export const REPORT_TYPES_ALL = {
  ...REPORT_TYPES_DEFAULT,
  ...REPORT_TYPES_WITH_CLUSTER_IMAGE,
  ...REPORT_TYPES_WITH_MANUALLY_ADDED,
};

export const DASHBOARD_TYPES = {
  PROJECT: 'project',
  PIPELINE: 'pipeline',
  GROUP: 'group',
  INSTANCE: 'instance',
};

export const PRIMARY_IDENTIFIER_TYPE = 'cve';

export const DAYS = { thirty: 30, sixty: 60, ninety: 90 };
