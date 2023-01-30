import { __, s__ } from '~/locale';
import {
  SAST_SHORT_NAME,
  DAST_SHORT_NAME,
  DEPENDENCY_SCANNING_NAME,
  SECRET_DETECTION_NAME,
  CONTAINER_SCANNING_NAME,
} from '~/security_configuration/components/constants';

export const SCANNER_DAST = 'dast';
export const DEFAULT_AGENT_NAME = '';
export const AGENT_KEY = 'agents';

export const SCAN_EXECUTION_RULES_LABELS = {
  pipeline: s__('ScanExecutionPolicy|A pipeline is run'),
  schedule: s__('ScanExecutionPolicy|Schedule'),
};

export const SCAN_EXECUTION_PIPELINE_RULE = 'pipeline';
export const SCAN_EXECUTION_SCHEDULE_RULE = 'schedule';

export const SCAN_EXECUTION_RULE_SCOPE_TYPE = {
  branch: s__('ScanExecutionPolicy|branch'),
  agent: s__('ScanExecutionPolicy|agent'),
};

export const SCAN_EXECUTION_RULE_PERIOD_TYPE = {
  daily: __('daily'),
  weekly: __('weekly'),
};

export const DEFAULT_SCANNER = SCANNER_DAST;

export const SCANNER_HUMANIZED_TEMPLATE = s__(
  'ScanExecutionPolicy|%{thenLabelStart}Then%{thenLabelEnd} Require a %{scan} scan to run with tags %{tags}',
);

export const DAST_HUMANIZED_TEMPLATE = s__(
  'ScanExecutionPolicy|%{thenLabelStart}Then%{thenLabelEnd} Require a %{scan} scan to run with site profile %{siteProfile} and scanner profile %{scannerProfile} with tags %{tags}',
);

export const RULE_MODE_SCANNERS = {
  sast: SAST_SHORT_NAME,
  dast: DAST_SHORT_NAME,
  secret_detection: SECRET_DETECTION_NAME,
  container_scanning: CONTAINER_SCANNING_NAME,
  dependency_scanning: DEPENDENCY_SCANNING_NAME,
};
