import { __, s__ } from '~/locale';
import {
  SAST_SHORT_NAME,
  DAST_SHORT_NAME,
  SECRET_DETECTION_NAME,
  CONTAINER_SCANNING_NAME,
  CLUSTER_IMAGE_SCANNING_NAME,
} from '~/security_configuration/components/constants';

export const SCANNER_DAST = 'dast';

export const SCAN_EXECUTION_RULES_LABELS = {
  pipeline: s__('ScanExecutionPolicy|A pipeline is run'),
  schedule: s__('ScanExecutionPolicy|Schedule'),
};

export const SCAN_EXECUTION_PIPELINE_RULE = 'pipeline';
export const SCAN_EXECUTION_SCHEDULE_RULE = 'schedule';

export const SCAN_EXECUTION_RULE_SCOPE_TYPE = {
  branch: s__('ScanExecutionPolicy|branch'),
};

export const SCAN_EXECUTION_RULE_PERIOD_TYPE = {
  daily: __('daily'),
  weekly: __('weekly'),
};

export const DEFAULT_SCANNER = SCANNER_DAST;

export const SCANNER_HUMANIZED_TEMPLATE = s__(
  'ScanExecutionPolicy|%{thenLabelStart}Then%{thenLabelEnd} Require a %{scan} scan to run',
);

export const DAST_HUMANIZED_TEMPLATE = s__(
  'ScanExecutionPolicy|%{thenLabelStart}Then%{thenLabelEnd} Require a %{scan} scan to run with site profile %{siteProfile} and scanner profile %{scannerProfile}',
);

// TODO remove after https://gitlab.com/gitlab-org/gitlab/-/issues/365579
export const TEMPORARY_LIST_OF_SCANNERS = {
  sast: SAST_SHORT_NAME,
  dast: DAST_SHORT_NAME,
  secret_detection: SECRET_DETECTION_NAME,
  container_scanning: CONTAINER_SCANNING_NAME,
  cluster_image_scanning: CLUSTER_IMAGE_SCANNING_NAME,
};
