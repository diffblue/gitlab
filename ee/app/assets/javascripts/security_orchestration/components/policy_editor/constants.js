import { s__, __ } from '~/locale';

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
