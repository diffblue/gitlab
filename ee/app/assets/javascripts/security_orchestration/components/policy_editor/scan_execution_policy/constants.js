import { __, s__ } from '~/locale';

export const SCANNER_DAST = 'dast';
export const DEFAULT_AGENT_NAME = '';
export const AGENT_KEY = 'agents';

export const SCAN_EXECUTION_RULES_PIPELINE_KEY = 'pipeline';
export const SCAN_EXECUTION_RULES_SCHEDULE_KEY = 'schedule';

export const SCAN_EXECUTION_RULES_LABELS = {
  [SCAN_EXECUTION_RULES_PIPELINE_KEY]: s__('ScanExecutionPolicy|A pipeline is run'),
  [SCAN_EXECUTION_RULES_SCHEDULE_KEY]: s__('ScanExecutionPolicy|Schedule'),
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

export const POLICY_ACTION_TAG_MODE_SPECIFIC_TAG_KEY = 'specific_tag';
export const POLICY_ACTION_TAG_MODE_SELECTED_AUTOMATICALLY_KEY = 'selected_automatically';
export const TAGS_MODE_SELECTED_ITEMS = [
  {
    text: s__('ScanExecutionPolicy|has specific tag'),
    value: POLICY_ACTION_TAG_MODE_SPECIFIC_TAG_KEY,
  },
  {
    text: s__('ScanExecutionPolicy|selected automatically'),
    value: POLICY_ACTION_TAG_MODE_SELECTED_AUTOMATICALLY_KEY,
  },
];

export const DEFAULT_SCANNER = SCANNER_DAST;

export const SCANNER_HUMANIZED_TEMPLATE = s__(
  'ScanExecutionPolicy|%{thenLabelStart}Then%{thenLabelEnd} Run a %{scan} scan on runner that %{tags}',
);

export const DAST_HUMANIZED_TEMPLATE = s__(
  'ScanExecutionPolicy|%{thenLabelStart}Then%{thenLabelEnd} Run a %{scan} scan with %{dastProfiles} with tags %{tags}',
);

export const POLICY_ACTION_BUILDER_TAGS_ERROR_KEY = 'tags';
export const POLICY_ACTION_BUILDER_DAST_PROFILES_ERROR_KEY = 'profiles';
export const CONTENT_WRAPPER_CONTAINER_CLASS = '.content-wrapper';
