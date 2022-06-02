import { s__ } from '~/locale';

export const NEW_POLICY_BUTTON_TEXT = s__('SecurityOrchestration|New policy');

export const POLICY_TYPE_COMPONENT_OPTIONS = {
  scanExecution: {
    component: 'scan-execution-policy-editor',
    text: s__('SecurityOrchestration|Scan Execution'),
    typeName: 'ScanExecutionPolicy',
    urlParameter: 'scan_execution_policy',
    value: 'scanExecution',
  },
  scanResult: {
    component: 'scan-result-policy-editor',
    text: s__('SecurityOrchestration|Scan Result'),
    typeName: 'ScanResultPolicy',
    urlParameter: 'scan_result_policy',
    value: 'scanResult',
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

export const POLICIES_LIST_CONTAINER_CLASS = '.js-security-policies-container-wrapper';
