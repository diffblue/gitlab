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

export const POLICIES_LIST_CONTAINER_CLASS = '.js-security-policies-container-wrapper';

export const EXCEPTION_KEY = 'exception';
export const NO_EXCEPTION_KEY = 'no_exception';
export const EXCEPTION_TYPE_ITEMS = [
  {
    value: EXCEPTION_KEY,
    text: s__('SecurityOrchestration|Exceptions'),
  },
  {
    value: NO_EXCEPTION_KEY,
    text: s__('SecurityOrchestration|No exceptions'),
  },
];
