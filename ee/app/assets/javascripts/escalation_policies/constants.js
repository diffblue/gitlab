import { s__ } from '~/locale';

export const ALERT_STATUSES = {
  ACKNOWLEDGED: s__('AlertManagement|Acknowledged'),
  RESOLVED: s__('AlertManagement|Resolved'),
};

export const EMAIL_ONCALL_SCHEDULE_USER = 'EMAIL_ONCALL_SCHEDULE_USER';
export const EMAIL_USER = 'EMAIL_USER';

export const ACTIONS = {
  [EMAIL_ONCALL_SCHEDULE_USER]: s__('EscalationPolicies|Email on-call user in schedule'),
  [EMAIL_USER]: s__('EscalationPolicies|Email user'),
};

export const DEFAULT_ESCALATION_RULE = {
  status: 'ACKNOWLEDGED',
  elapsedTimeMinutes: 0,
  action: 'EMAIL_ONCALL_SCHEDULE_USER',
  oncallScheduleIid: null,
};

export const addEscalationPolicyModalId = 'addEscalationPolicyModal';
export const editEscalationPolicyModalId = 'editEscalationPolicyModal';
export const deleteEscalationPolicyModalId = 'deleteEscalationPolicyModal';

export const MAX_RULES_LENGTH = 10;
