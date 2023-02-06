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
  INCIDENT: 'incident_events',
  VULNERABILITY: 'vulnerability_events',
};

export const integrationTriggerEventTitles = {
  ...integrationTriggerEventTitlesCE,
  [integrationTriggerEvents.ALERT]: s__('IntegrationEvents|A new, unique alert is recorded'),
  [integrationTriggerEvents.INCIDENT]: s__(
    'IntegrationEvents|An incident is created, closed, or reopened',
  ),
  [integrationTriggerEvents.VULNERABILITY]: s__(
    'IntegrationEvents|A new, unique vulnerability is recorded (available only in GitLab Ultimate)',
  ),
};
/* eslint-enable import/export */
