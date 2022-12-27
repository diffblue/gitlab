import { s__ } from '~/locale';

import {
  integrationTriggerEvents as integrationTriggerEventsCE,
  integrationTriggerEventTitles as integrationTriggerEventTitlesCE,
} from '~/integrations/constants';

/* eslint-disable import/export */
export * from '~/integrations/constants';

export const integrationTriggerEvents = {
  ...integrationTriggerEventsCE,
  ALERT: 'alert_events',
  VULNERABILITY: 'vulnerability_events',
};

export const integrationTriggerEventTitles = {
  ...integrationTriggerEventTitlesCE,
  [integrationTriggerEvents.ALERT]: s__('IntegrationEvents|A new, unique alert is recorded'),
  [integrationTriggerEvents.VULNERABILITY]: s__(
    'IntegrationEvents|A new, unique, vulnerability is recorded. (Note: This feature requires an Ultimate plan)',
  ),
};
/* eslint-enable import/export */
