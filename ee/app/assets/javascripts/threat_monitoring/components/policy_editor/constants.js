import { s__, __ } from '~/locale';

export const EDITOR_MODE_RULE = 'rule';
export const EDITOR_MODE_YAML = 'yaml';

export const PARSING_ERROR_MESSAGE = s__(
  'NetworkPolicies|Rule mode is unavailable for this policy. In some cases, we cannot parse the YAML file back into the rules editor.',
);

export const EDITOR_MODES = [
  { value: EDITOR_MODE_RULE, text: s__('NetworkPolicies|Rule mode') },
  { value: EDITOR_MODE_YAML, text: s__('NetworkPolicies|.yaml mode') },
];

export const DELETE_MODAL_CONFIG = {
  id: 'delete-modal',
  secondary: {
    text: s__('NetworkPolicies|Delete policy'),
    attributes: { variant: 'danger' },
  },
  cancel: {
    text: __('Cancel'),
  },
};
