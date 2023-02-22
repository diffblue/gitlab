import { __, s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export const COLLAPSE_SECURITY_REPORTS_SUMMARY_LOCAL_STORAGE_KEY =
  'hide_pipelines_security_reports_summary_details';

export const DEFAULT_SCANNER = 'GitLab';
export const SCANNER_ID_PREFIX = 'gid://gitlab/Vulnerabilities::Scanner/';

export const DOC_PATH_APPLICATION_SECURITY = helpPagePath('user/application_security/index');
export const DOC_PATH_VULNERABILITY_DETAILS = helpPagePath(
  'user/application_security/vulnerabilities/index',
);
export const DOC_PATH_VULNERABILITY_REPORT = helpPagePath(
  'user/application_security/vulnerability_report/index',
);
export const DOC_PATH_SECURITY_CONFIGURATION = helpPagePath(
  'user/application_security/configuration/index',
);
export const DOC_PATH_SECURITY_SCANNER_INTEGRATION_REPORT = helpPagePath(
  'development/integrations/secure',
  { anchor: 'report' },
);
export const DOC_PATH_SECURITY_SCANNER_INTEGRATION_RETENTION_PERIOD = helpPagePath(
  'development/integrations/secure',
  { anchor: 'retention-period-for-vulnerabilities' },
);

export const severityLevels = {
  CRITICAL: 'critical',
  HIGH: 'high',
  UNKNOWN: 'unknown',
  MEDIUM: 'medium',
  LOW: 'low',
  NONE: 'none',
};

export const severityLevelsTranslations = {
  [severityLevels.CRITICAL]: s__('severity|Critical'),
  [severityLevels.HIGH]: s__('severity|High'),
  [severityLevels.UNKNOWN]: s__('severity|Unknown'),
  [severityLevels.MEDIUM]: s__('severity|Medium'),
  [severityLevels.LOW]: s__('severity|Low'),
  [severityLevels.NONE]: s__('severity|None'),
};

export const SEVERITY_LEVELS_ORDERED_BY_SEVERITY = [
  severityLevels.CRITICAL,
  severityLevels.HIGH,
  severityLevels.UNKNOWN,
  severityLevels.MEDIUM,
  severityLevels.LOW,
  severityLevels.NONE,
];

export const severityGroupTypes = {
  F: 'F',
  D: 'D',
  C: 'C',
  B: 'B',
  A: 'A',
};

export const SEVERITY_GROUPS = [
  {
    type: severityGroupTypes.F,
    description: __('Projects with critical vulnerabilities'),
    warning: __('Critical vulnerabilities present'),
    severityLevels: [severityLevels.CRITICAL],
  },
  {
    type: severityGroupTypes.D,
    description: __('Projects with high or unknown vulnerabilities'),
    warning: __('High or unknown vulnerabilities present'),
    severityLevels: [severityLevels.HIGH, severityLevels.UNKNOWN],
  },
  {
    type: severityGroupTypes.C,
    description: __('Projects with medium vulnerabilities'),
    warning: __('Medium vulnerabilities present'),
    severityLevels: [severityLevels.MEDIUM],
  },
  {
    type: severityGroupTypes.B,
    description: __('Projects with low vulnerabilities'),
    warning: __('Low vulnerabilities present'),
    severityLevels: [severityLevels.LOW],
  },
  {
    type: severityGroupTypes.A,
    description: __('Projects with no vulnerabilities and security scanning enabled'),
    warning: __('No vulnerabilities present'),
    severityLevels: [severityLevels.NONE],
  },
];
