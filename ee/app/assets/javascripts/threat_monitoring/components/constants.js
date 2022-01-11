import { gray700, orange400 } from '@gitlab/ui/scss_to_js/scss_variables';
import { s__ } from '~/locale';

export const TOTAL_REQUESTS = s__('ThreatMonitoring|Total Requests');
export const ANOMALOUS_REQUESTS = s__('ThreatMonitoring|Anomalous Requests');
export const TIME = s__('ThreatMonitoring|Time');
export const REQUESTS = s__('ThreatMonitoring|Requests');
export const NO_ENVIRONMENT_TITLE = s__('ThreatMonitoring|No environments detected');
export const EMPTY_STATE_DESCRIPTION = s__(
  `ThreatMonitoring|To view this data, ensure you have configured an environment
    for this project and that at least one threat monitoring feature is enabled. %{linkStart}More information%{linkEnd}`,
);
export const NEW_POLICY_BUTTON_TEXT = s__('SecurityOrchestration|New policy');

export const COLORS = {
  nominal: gray700,
  anomalous: orange400,
};

// Reuse existing definitions rather than defining them again here,
// otherwise they could get out of sync.
// See https://gitlab.com/gitlab-org/gitlab-ui/issues/554.
export { dateFormats as DATE_FORMATS } from '~/analytics/shared/constants';

export const POLICY_TYPE_COMPONENT_OPTIONS = {
  container: {
    component: 'network-policy-editor',
    kind: {
      cilium: 'CiliumNetworkPolicy',
      network: 'NetworkPolicy',
    },
    shouldShowEnvironmentPicker: true,
    text: s__('SecurityOrchestration|Network'),
    typeName: 'NetworkPolicy',
    urlParameter: 'container_policy',
    value: 'container',
  },
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
  POLICY_TYPE_NETWORK: {
    value: 'POLICY_TYPE_NETWORK',
    text: s__('SecurityOrchestration|Network'),
  },
  POLICY_TYPE_SCAN_EXECUTION: {
    value: 'POLICY_TYPE_SCAN_EXECUTION',
    text: s__('SecurityOrchestration|Scan execution'),
  },
  POLICY_TYPE_SCAN_RESULT: {
    value: 'POLICY_TYPE_SCAN_RESULT',
    text: s__('SecurityOrchestration|Scan result'),
  },
  ALL: {
    value: '',
    text: s__('SecurityOrchestration|All policies'),
  },
};

export const POLICIES_LIST_CONTAINER_CLASS = '.js-security-policies-container-wrapper';
