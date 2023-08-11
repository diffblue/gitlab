import { buildApiUrl } from '~/api/api_utils';
import axios from '~/lib/utils/axios_utils';

const SUBSCRIPTIONS_PATH = '/api/:version/subscriptions';

export function createSubscription(groupId, customer, subscription) {
  const url = buildApiUrl(SUBSCRIPTIONS_PATH);
  const params = {
    selectedGroup: groupId,
    customer,
    subscription,
  };

  return axios.post(url, { params });
}

export const sendHandRaiseLead = async (createHandRaiseLeadPath, params) => {
  const url = buildApiUrl(createHandRaiseLeadPath);
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
