import { s__, __ } from '~/locale';
import {
  SAST_SHORT_NAME,
  DAST_SHORT_NAME,
  DEPENDENCY_SCANNING_NAME,
  SECRET_DETECTION_NAME,
  CONTAINER_SCANNING_NAME,
  SAST_IAC_SHORT_NAME,
} from '~/security_configuration/components/constants';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';

export const EDITOR_MODE_RULE = 'rule';
export const EDITOR_MODE_YAML = 'yaml';

export const PARSING_ERROR_MESSAGE = s__(
  'SecurityOrchestration|Rule mode is unavailable for this policy. In some cases, we cannot parse the YAML file back into the rules editor.',
);

export const EDITOR_MODES = [
  { value: EDITOR_MODE_RULE, text: s__('SecurityOrchestration|Rule mode') },
  { value: EDITOR_MODE_YAML, text: s__('SecurityOrchestration|.yaml mode') },
];

export const DELETE_MODAL_CONFIG = {
  id: 'delete-modal',
  secondary: {
    text: s__('SecurityOrchestration|Delete policy'),
    attributes: { variant: 'danger' },
  },
  cancel: {
    text: __('Cancel'),
  },
};

export const DEFAULT_MR_TITLE = s__('SecurityOrchestration|Update scan policies');

export const POLICY_RUN_TIME_MESSAGE = s__(
  'SecurityOrchestration|Policy changes may take some time to be applied.',
);

export const POLICY_RUN_TIME_TOOLTIP = s__(
  'SecurityOrchestration|For large groups, there may be a significant delay in applying policy changes to pre-existing merge requests. Policy changes typically apply almost immediately for newly created merge requests.',
);

export const SECURITY_POLICY_ACTIONS = Object.freeze({
  APPEND: 'APPEND',
  REMOVE: 'REMOVE',
  REPLACE: 'REPLACE',
});

export const GRAPHQL_ERROR_MESSAGE = s__(
  'SecurityOrchestration|There was a problem creating the new security policy',
);

export const NO_RULE_MESSAGE = s__('SecurityOrchestration|No rules defined - policy will not run.');

export const ACTIONS = {
  tags: 'TAGS',
  variables: 'VARIABLES',
};

export const INVALID_RULE_MESSAGE = s__(
  'SecurityOrchestration|Invalid branch type detected - rule will not be applied.',
);

export const INVALID_PROTECTED_BRANCHES = s__(
  'SecurityOrchestration|The following branches do not exist on this development project: %{branches}. Please review all protected branches to ensure the values are accurate before updating this policy.',
);
export const ADD_RULE_LABEL = s__('SecurityOrchestration|Add rule');
export const RULES_LABEL = s__('SecurityOrchestration|Rules');

export const ADD_ACTION_LABEL = s__('SecurityOrchestration|Add action');
export const ACTIONS_LABEL = s__('SecurityOrchestration|Actions');

export const RULE_IF_LABEL = __('if');
export const RULE_OR_LABEL = __('or');

export const ACTION_AND_LABEL = __('and');

export const RULE_MODE_SCANNERS = {
  sast: SAST_SHORT_NAME,
  sast_iac: SAST_IAC_SHORT_NAME,
  dast: DAST_SHORT_NAME,
  secret_detection: SECRET_DETECTION_NAME,
  container_scanning: CONTAINER_SCANNING_NAME,
  dependency_scanning: DEPENDENCY_SCANNING_NAME,
};

export const MAX_ALLOWED_RULES_LENGTH = 5;

export const PRIMARY_POLICY_KEYS = ['type', 'name', 'description', 'enabled', 'rules', 'actions'];

export const SPECIFIC_BRANCHES = {
  id: 'SPECIFIC_BRANCHES',
  text: __('specific protected branches'),
  value: 'SPECIFIC_BRANCHES',
};

export const ALL_BRANCHES = {
  text: __('all branches'),
  value: 'all',
};

export const GROUP_DEFAULT_BRANCHES = {
  text: __('all default branches'),
  value: 'default',
};

export const PROJECT_DEFAULT_BRANCH = {
  text: __('default branch'),
  value: 'default',
};

export const ALL_PROTECTED_BRANCHES = {
  text: __('all protected branches'),
  value: 'protected',
};

export const ANY_OPERATOR = 'ANY';

export const GREATER_THAN_OPERATOR = 'greater_than';

export const LESS_THAN_OPERATOR = 'less_than';

export const VULNERABILITIES_ALLOWED_OPERATORS = [
  { value: ANY_OPERATOR, text: s__('ApprovalRule|Any') },
  { value: GREATER_THAN_OPERATOR, text: s__('ApprovalRule|More than') },
];

export const VULNERABILITY_AGE_OPERATORS = [
  { value: ANY_OPERATOR, text: s__('ApprovalRule|Any') },
  { value: GREATER_THAN_OPERATOR, text: s__('ApprovalRule|Greater than') },
  { value: LESS_THAN_OPERATOR, text: s__('ApprovalRule|Less than') },
];

export const SCAN_RESULT_BRANCH_TYPE_OPTIONS = (nameSpaceType = NAMESPACE_TYPES.GROUP) => [
  nameSpaceType === NAMESPACE_TYPES.GROUP ? GROUP_DEFAULT_BRANCHES : PROJECT_DEFAULT_BRANCH,
  ALL_PROTECTED_BRANCHES,
  SPECIFIC_BRANCHES,
];

export const SCAN_EXECUTION_BRANCH_TYPE_OPTIONS = (nameSpaceType = NAMESPACE_TYPES.GROUP) => [
  ALL_BRANCHES,
  nameSpaceType === NAMESPACE_TYPES.GROUP ? GROUP_DEFAULT_BRANCHES : PROJECT_DEFAULT_BRANCH,
  ALL_PROTECTED_BRANCHES,
  SPECIFIC_BRANCHES,
];
export const VALID_SCAN_EXECUTION_BRANCH_TYPE_OPTIONS = [
  ALL_BRANCHES.value,
  ALL_PROTECTED_BRANCHES.value,
  GROUP_DEFAULT_BRANCHES.value,
];
export const VALID_SCAN_RESULT_BRANCH_TYPE_OPTIONS = [
  ALL_PROTECTED_BRANCHES.value,
  GROUP_DEFAULT_BRANCHES.value,
];

export const BRANCHES_KEY = 'branches';
export const BRANCH_TYPE_KEY = 'branch_type';
export const BRANCH_EXCEPTIONS_KEY = 'branch_exceptions';

export const HUMANIZED_BRANCH_TYPE_TEXT_DICT = {
  [ALL_BRANCHES.value]: s__('SecurityOrchestration|any branch'),
  [ALL_PROTECTED_BRANCHES.value]: s__('SecurityOrchestration|any protected branch'),
  [GROUP_DEFAULT_BRANCHES.value]: s__('SecurityOrchestration|any default branch'),
  [PROJECT_DEFAULT_BRANCH.value]: s__('SecurityOrchestration|the default branch'),
};
