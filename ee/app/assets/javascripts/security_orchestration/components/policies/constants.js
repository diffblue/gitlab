import { s__ } from '~/locale';

export const POLICY_SOURCE_OPTIONS = {
  ALL: {
    value: 'INHERITED',
    text: s__('SecurityOrchestration|All sources'),
  },
  DIRECT: {
    value: 'DIRECT',
    text: s__('SecurityOrchestration|Direct'),
  },
  INHERITED: {
    value: 'INHERITED_ONLY',
    text: s__('SecurityOrchestration|Inherited'),
  },
};

export const POLICY_TYPE_FILTER_OPTIONS = {
  ALL: {
    value: '',
    text: s__('SecurityOrchestration|All types'),
  },
  POLICY_TYPE_SCAN_EXECUTION: {
    value: 'POLICY_TYPE_SCAN_EXECUTION',
    text: s__('SecurityOrchestration|Scan execution'),
  },
  POLICY_TYPE_SCAN_RESULT: {
    value: 'POLICY_TYPE_SCAN_RESULT',
    text: s__('SecurityOrchestration|Scan result'),
  },
};

export const POLICY_TYPES_WITH_INHERITANCE = [
  POLICY_TYPE_FILTER_OPTIONS.POLICY_TYPE_SCAN_EXECUTION.value,
  POLICY_TYPE_FILTER_OPTIONS.POLICY_TYPE_SCAN_RESULT.value,
];

export const EMPTY_LIST_DESCRIPTION = s__(
  'SecurityOrchestration|This %{namespaceType} does not contain any security policies.',
);

export const EMPTY_POLICY_PROJECT_DESCRIPTION = s__(
  'SecurityOrchestration|This %{namespaceType} is not linked to a security policy project',
);

export const POLICY_PROJECT_LINK_SUCCESS_MESSAGE = s__(
  'SecurityOrchestration|Security policy project was linked successfully',
);

export const POLICY_PROJECT_LINK_ERROR_MESSAGE = s__(
  'SecurityOrchestration|An error occurred assigning your security policy project',
);
