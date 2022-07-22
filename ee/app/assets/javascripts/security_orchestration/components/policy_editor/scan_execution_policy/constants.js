import { s__ } from '~/locale';
import {
  SAST_SHORT_NAME,
  DAST_SHORT_NAME,
  SECRET_DETECTION_NAME,
  CONTAINER_SCANNING_NAME,
  CLUSTER_IMAGE_SCANNING_NAME,
} from '~/security_configuration/components/constants';

export const SCAN_EXECUTION_RULES_LABELS = {
  pipeline: s__('ScanExecutionPolicy|A pipeline is run'),
  schedule: s__('ScanExecutionPolicy|Schedule'),
};

export const SCAN_EXECUTION_PIPELINE_RULE = 'pipeline';
export const SCAN_EXECUTION_SCHEDULE_RULE = 'schedule';

export const DEFAULT_AGENT_NAME = 'default';

export const SCAN_EXECUTION_RULE_SCOPE_TYPE = {
  branch: s__('ScanResultPolicy|branch'),
  cluster: s__('ScanResultPolicy|cluster'),
};

export const SCAN_EXECUTION_RULE_PERIOD_TYPE = {
  daily: s__('ScanResultPolicy|daily'),
  weekly: s__('ScanResultPolicy|weekly'),
};

export const DEFAULT_SCAN = 'dast';

export const TEMPORARY_LIST_OF_SCANS = {
  sast: SAST_SHORT_NAME,
  dast: DAST_SHORT_NAME,
  secret_detection: SECRET_DETECTION_NAME,
  container_scanning: CONTAINER_SCANNING_NAME,
  cluster_image_scanning: CLUSTER_IMAGE_SCANNING_NAME,
};
