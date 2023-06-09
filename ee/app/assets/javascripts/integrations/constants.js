import { s__ } from '~/locale';

import {
  integrationTriggerEvents as integrationTriggerEventsCE,
  integrationTriggerEventTitles as integrationTriggerEventTitlesCE,
} from '~/integrations/constants';

/* eslint-disable import/export */
export * from '~/integrations/constants';

export const integrationTriggerEvents = {
  ...integrationTriggerEventsCE,
  VULNERABILITY: 'vulnerability_events',
};

export const integrationTriggerEventTitles = {
  ...integrationTriggerEventTitlesCE,
  [integrationTriggerEvents.VULNERABILITY]: s__(
    'IntegrationEvents|A new, unique vulnerability is recorded (available only in GitLab Ultimate)',
  ),
};
/* eslint-enable import/export */
