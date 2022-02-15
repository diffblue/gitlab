import { s__, __ } from '~/locale';
import { SIDEBAR_ESCALATION_POLICY_TITLE, none } from '../../constants';

export const i18nHelpText = {
  title: s__('IncidentManagement|Page your team with escalation policies'),
  detail: s__(
    'IncidentManagement|Use escalation policies to automatically page your team when incidents are created.',
  ),
  linkText: __('Learn more'),
};

export const i18nPolicyText = {
  paged: s__('IncidentManagement|Paged'),
  title: SIDEBAR_ESCALATION_POLICY_TITLE,
  none,
};
