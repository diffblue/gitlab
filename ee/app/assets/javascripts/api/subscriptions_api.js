import { buildApiUrl } from '~/api/api_utils';
import axios from '~/lib/utils/axios_utils';

const SUBSCRIPTIONS_PATH = '/api/:version/subscriptions';
const EXTEND_REACTIVATE_TRIAL_PATH = '/-/trials/extend_reactivate';

const TRIAL_EXTENSION_TYPE = Object.freeze({
  extended: 1,
  reactivated: 2,
});

export function createSubscription(groupId, customer, subscription) {
  const url = buildApiUrl(SUBSCRIPTIONS_PATH);
  const params = {
    selectedGroup: groupId,
    customer,
    subscription,
  };

  return axios.post(url, { params });
}

const updateTrial = async (namespaceId, trialExtensionType) => {
  if (!Object.values(TRIAL_EXTENSION_TYPE).includes(trialExtensionType)) {
    throw new TypeError('The "trialExtensionType" argument is invalid.');
  }

  const url = buildApiUrl(EXTEND_REACTIVATE_TRIAL_PATH);
  const params = {
    namespace_id: namespaceId,
    trial_extension_type: trialExtensionType,
  };

  return axios.put(url, params);
};

export const extendTrial = async (namespaceId) => {
  return updateTrial(namespaceId, TRIAL_EXTENSION_TYPE.extended);
};

export const reactivateTrial = async (namespaceId) => {
  return updateTrial(namespaceId, TRIAL_EXTENSION_TYPE.reactivated);
};
