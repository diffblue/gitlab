import { s__, __ } from '~/locale';
import {
  SAST_SHORT_NAME,
  DAST_SHORT_NAME,
  DEPENDENCY_SCANNING_NAME,
  SECRET_DETECTION_NAME,
  CONTAINER_SCANNING_NAME,
  SAST_IAC_SHORT_NAME,
} from '~/security_configuration/components/constants';

export const EDITOR_MODE_RULE = 'rule';
export const EDITOR_MODE_YAML = 'yaml';

export const PARSING_ERROR_MESSAGE = s__(
  'SecurityOrchestration|Rule mode is unavailable for this policy. In some cases, we cannot parse the YAML file back into the rules editor.',
);

export const RUNNER_TAGS_PARSING_ERROR = s__(
  'SecurityOrchestration|Non-existing tags have been detected in the policy yaml. As a result, rule mode has been disabled. To enable rule mode, remove those non-existing tags from the policy yaml.',
);

export const DAST_SCANNERS_PARSING_ERROR = s__(
  'SecurityOrchestration|Non-existing DAST profiles have been detected in the policy yaml. As a result, rule mode has been disabled. To enable rule mode, remove those non-existing profiles from the policy yaml.',
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

export const INVALID_PROTECTED_BRANCHES = s__(
  'SecurityOrchestration|The following branches do not exist on this development project: %{branches}. Please review all protected branches to ensure the values are accurate before updating this policy.',
);

export const ADD_RULE_LABEL = s__('SecurityOrchestration|Add rule');
export const RULES_LABEL = s__('SecurityOrchestration|Rules');

export const ADD_ACTION_LABEL = s__('SecurityOrchestration|Add action');
export const ACTIONS_LABEL = s__('SecurityOrchestration|Actions');

export const RULE_IF_LABEL = __('if');
export const RULE_OR_LABEL = __('or');

export const ACTION_THEN_LABEL = __('then');
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
  text: __('Specific branches'),
  value: 'SPECIFIC_BRANCHES',
};

export const ANY_OPERATOR = 'ANY';

export const MORE_THAN_OPERATOR = 'MORE_THAN';

export const NUMBER_RANGE_I18N_MAP = {
  [ANY_OPERATOR]: s__('ApprovalRule|Any'),
  [MORE_THAN_OPERATOR]: s__('ApprovalRule|More than'),
};
