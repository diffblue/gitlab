import { stateToComponentMap as ceStateMap } from '~/vue_merge_request_widget/stores/state_maps';

export { statesToShowHelpWidget } from '~/vue_merge_request_widget/stores/state_maps';
export const stateKey = {
  policyViolation: 'policyViolation',
  jiraAssociationMissing: 'jiraAssociationMissing',
};
export const stateToComponentMap = {
  ...ceStateMap,
  geoSecondaryNode: 'mr-widget-geo-secondary-node',
  policyViolation: 'mr-widget-policy-violation',
  jiraAssociationMissing: 'mr-widget-jira-association-missing',
};
