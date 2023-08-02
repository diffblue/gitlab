import { __, s__ } from '~/locale';

export const SCANNER_DAST = 'dast';
export const DEFAULT_AGENT_NAME = '';
export const AGENT_KEY = 'agents';

export const SCAN_EXECUTION_RULES_PIPELINE_KEY = 'pipeline';
export const SCAN_EXECUTION_RULES_SCHEDULE_KEY = 'schedule';

export const SCAN_EXECUTION_RULES_LABELS = {
  [SCAN_EXECUTION_RULES_PIPELINE_KEY]: s__('ScanExecutionPolicy|Triggers:'),
  [SCAN_EXECUTION_RULES_SCHEDULE_KEY]: s__('ScanExecutionPolicy|Schedules:'),
};

export const ADD_CONDITION_LABEL = s__('ScanExecutionPolicy|Add condition');
export const CONDITIONS_LABEL = s__('ScanExecutionPolicy|Conditions');

export const SCAN_EXECUTION_PIPELINE_RULE = 'pipeline';
export const SCAN_EXECUTION_SCHEDULE_RULE = 'schedule';

export const SCAN_EXECUTION_RULE_SCOPE_BRANCH_KEY = 'branch';
export const SCAN_EXECUTION_RULE_SCOPE_AGENT_KEY = 'agent';
export const SCAN_EXECUTION_RULE_SCOPE_TYPE = {
  [SCAN_EXECUTION_RULE_SCOPE_BRANCH_KEY]: s__('ScanExecutionPolicy|branch'),
  [SCAN_EXECUTION_RULE_SCOPE_AGENT_KEY]: s__('ScanExecutionPolicy|agent'),
};

export const SCAN_EXECUTION_RULE_PERIOD_DAILY_KEY = 'daily';
export const SCAN_EXECUTION_RULE_PERIOD_WEEKLY_KEY = 'weekly';
export const SCAN_EXECUTION_RULE_PERIOD_TYPE = {
  [SCAN_EXECUTION_RULE_PERIOD_DAILY_KEY]: __('daily'),
  [SCAN_EXECUTION_RULE_PERIOD_WEEKLY_KEY]: __('weekly'),
};

export const ACTION_RUNNER_TAG_MODE_SPECIFIC_TAG_KEY = 'specific_tag';
export const ACTION_RUNNER_TAG_MODE_SELECTED_AUTOMATICALLY_KEY = 'selected_automatically';

export const TAGS_MODE_SELECTED_ITEMS = [
  {
    text: s__('ScanExecutionPolicy|has specific tag'),
    value: ACTION_RUNNER_TAG_MODE_SPECIFIC_TAG_KEY,
  },
  {
    text: s__('ScanExecutionPolicy|selected automatically'),
    value: ACTION_RUNNER_TAG_MODE_SELECTED_AUTOMATICALLY_KEY,
  },
];

export const DEFAULT_SCANNER = SCANNER_DAST;

export const SCANNER_HUMANIZED_TEMPLATE = s__(
  'ScanExecutionPolicy|Run a %{scan} scan with the following options:',
);

export const POLICY_ACTION_BUILDER_TAGS_ERROR_KEY = 'tags';
export const POLICY_ACTION_BUILDER_DAST_PROFILES_ERROR_KEY = 'profiles';

export const RUNNER_TAGS_PARSING_ERROR = s__(
  'SecurityOrchestration|Non-existing tags have been detected in the policy yaml. As a result, rule mode has been disabled. To enable rule mode, remove those non-existing tags from the policy yaml.',
);

export const DAST_SCANNERS_PARSING_ERROR = s__(
  'SecurityOrchestration|Non-existing DAST profiles have been detected in the policy yaml. As a result, rule mode has been disabled. To enable rule mode, remove those non-existing profiles from the policy yaml.',
);

export const ERROR_MESSAGE_MAP = {
  [POLICY_ACTION_BUILDER_TAGS_ERROR_KEY]: RUNNER_TAGS_PARSING_ERROR,
  [POLICY_ACTION_BUILDER_DAST_PROFILES_ERROR_KEY]: DAST_SCANNERS_PARSING_ERROR,
};
