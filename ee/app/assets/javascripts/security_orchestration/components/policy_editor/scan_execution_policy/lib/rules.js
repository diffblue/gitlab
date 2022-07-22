import { SCAN_EXECUTION_PIPELINE_RULE, SCAN_EXECUTION_SCHEDULE_RULE } from '../constants';
import { CRONE_DEFAULT_TIME } from './cron';

export function buildDefaultPipeLineRule() {
  return {
    type: SCAN_EXECUTION_PIPELINE_RULE,
    branches: [],
  };
}

export function buildDefaultScheduleRule() {
  return {
    type: SCAN_EXECUTION_SCHEDULE_RULE,
    branches: [],
    cadence: CRONE_DEFAULT_TIME,
  };
}

export const RULE_KEY_MAP = {
  [SCAN_EXECUTION_PIPELINE_RULE]: buildDefaultPipeLineRule,
  [SCAN_EXECUTION_SCHEDULE_RULE]: buildDefaultScheduleRule,
};
