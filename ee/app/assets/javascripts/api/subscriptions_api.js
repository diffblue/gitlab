import { buildApiUrl } from '~/api/api_utils';
import axios from '~/lib/utils/axios_utils';

const SUBSCRIPTIONS_PATH = '/api/:version/subscriptions';
const CREATE_HAND_RAISE_LEAD_PATH = '/-/subscriptions/hand_raise_leads';

export function createSubscription(groupId, customer, subscription) {
  const url = buildApiUrl(SUBSCRIPTIONS_PATH);
  const params = {
    selectedGroup: groupId,
    customer,
    subscription,
  };

  return axios.post(url, { params });
}

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
