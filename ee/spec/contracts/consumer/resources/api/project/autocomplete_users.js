import axios from 'axios';

import {
  AUTOCOMPLETE_USERS_URL,
  TEST_PROJECT_ID,
  TEST_MERGE_REQUEST_IID,
} from '../../../test_constants';

export async function getSuggestedReviewers(endpoint) {
  const { url } = endpoint;

  return axios({
    method: 'GET',
    baseURL: url,
    url: AUTOCOMPLETE_USERS_URL,
    headers: { Accept: '*/*' },
    params: {
      active: 'true',
      project_id: TEST_PROJECT_ID,
      merge_request_iid: TEST_MERGE_REQUEST_IID,
      current_user: 'true',
    },
  }).then((response) => response.data);
}
