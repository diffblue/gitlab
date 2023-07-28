import CEGetStateKey from '~/vue_merge_request_widget/stores/get_state_key';
import { DETAILED_MERGE_STATUS, MWCP_MERGE_STRATEGY } from '~/vue_merge_request_widget/constants';
import { stateKey as CEStateKey } from '~/vue_merge_request_widget/stores/state_maps';
import { stateKey } from './state_maps';

export default function getStateKey() {
  if (this.isGeoSecondaryNode) {
    return 'geoSecondaryNode';
  }

  if (this.detailedMergeStatus === DETAILED_MERGE_STATUS.POLICIES_DENIED) {
    return stateKey.policyViolation;
  }

  if (this.jiraAssociation?.enforced && this.jiraAssociation?.issue_keys.length === 0) {
    return stateKey.jiraAssociationMissing;
  }

  if (
    !this.autoMergeEnabled &&
    this.detailedMergeStatus === DETAILED_MERGE_STATUS.NOT_APPROVED &&
    this.preferredAutoMergeStrategy === MWCP_MERGE_STRATEGY
  ) {
    return CEStateKey.readyToMerge;
  }

  return CEGetStateKey.call(this);
}
