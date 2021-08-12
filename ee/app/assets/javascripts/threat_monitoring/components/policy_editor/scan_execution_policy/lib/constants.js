import { s__ } from '~/locale';

export const DEFAULT_MR_TITLE = s__('SecurityOrchestration|Update scan execution policies');

export const GRAPHQL_ERROR_MESSAGE = s__(
  'SecurityOrchestration|There was a problem creating the new security policy',
);

export const SECURITY_POLICY_ACTIONS = {
  APPEND: 'APPEND',
  REMOVE: 'REMOVE',
  REPLACE: 'REPLACE',
};
