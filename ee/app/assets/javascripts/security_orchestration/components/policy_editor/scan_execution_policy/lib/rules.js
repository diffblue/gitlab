import { SCAN_EXECUTION_PIPELINE_RULE, SCAN_EXECUTION_SCHEDULE_RULE } from '../constants';

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
    cadence: '0 0 * * *',
  };
}

export const RULE_KEY_MAP = {
  [SCAN_EXECUTION_PIPELINE_RULE]: buildDefaultPipeLineRule,
  [SCAN_EXECUTION_SCHEDULE_RULE]: buildDefaultScheduleRule,
};
