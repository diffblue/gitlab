import { __, s__ } from '~/locale';

export const ALERT_COOKIE_KEY = 'agent-vulnerabilities-info-alert-dismissed';

export const ALERT_MESSAGE = s__(
  'SecurityOrchestration|This view only shows scan results for the agent %{agent}. You can view scan results for all agents in the %{linkStart}Operational Vulnerabilities tab of the vulnerability report%{linkEnd}.',
);

export const ALERT_TITLE = s__('SecurityOrchestration|Latest scan run against %{agent}');

export const MODAL_ACTIONS = {
  primary: { text: __('Dismiss Alert') },
  secondary: { text: __('Cancel') },
};

export const MODAL_MESSAGE = s__(
  'SecurityOrchestration|After dismissing the alert, the information will never be shown again.',
);

export const MODAL_TITLE = s__("SecurityOrchestration|Don't show the alert anymore");

export const VULNERABILITY_REPORT_OPERATIONAL_TAB_LINK_LOCATION =
  '/-/security/vulnerability_report/?tab=OPERATIONAL';

/**
 * Tracks snowplow event when user views report details
 */
export const trackAgentSecurityTabAlert = {
  category: 'Vulnerability_Management',
  action: 'agent_security_tab_alert',
};
