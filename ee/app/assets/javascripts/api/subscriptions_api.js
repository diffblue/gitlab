import { buildApiUrl } from '~/api/api_utils';
import axios from '~/lib/utils/axios_utils';

const SUBSCRIPTIONS_PATH = '/api/:version/subscriptions';
const EXTEND_REACTIVATE_TRIAL_PATH = '/-/trials/extend_reactivate';
const CREATE_HAND_RAISE_LEAD_PATH = '/-/trials/create_hand_raise_lead';

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

export const sendHandRaiseLead = async (params) => {
  const url = buildApiUrl(CREATE_HAND_RAISE_LEAD_PATH);
  const formParams = {
    namespace_id: params.namespaceId,
    company_name: params.companyName,
    company_size: params.companySize,
    first_name: params.firstName,
    last_name: params.lastName,
    phone_number: params.phoneNumber,
    country: params.country,
    state: params.state,
    comment: params.comment,
    glm_content: params.glmContent,
  };

  return axios.post(url, formParams);
};
