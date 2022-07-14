import { s__ } from '~/locale';

export const POLICY_SOURCE_OPTIONS = {
  ALL: {
    value: 'INHERITED',
    text: s__('SecurityOrchestration|All policies'),
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

export const POLICY_TYPE_OPTIONS = {
  ALL: {
    value: '',
    text: s__('SecurityOrchestration|All policies'),
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

export const POLICY_TYPES_WITH_INHERITANCE = [POLICY_TYPE_OPTIONS.POLICY_TYPE_SCAN_EXECUTION.value];
