import { Matchers } from '@pact-foundation/pact';
import {
  AUTOCOMPLETE_USERS_URL,
  TEST_PROJECT_ID,
  TEST_MERGE_REQUEST_IID,
} from '../../../test_constants';

const userIdMatchExample1 = 6954442;
const userIdMatchExample2 = 6954441;

const body = [
  {
    id: Matchers.integer(userIdMatchExample1),
    username: Matchers.string('user1'),
    name: Matchers.string('A User'),
  },
  {
    id: Matchers.integer(userIdMatchExample2),
    username: Matchers.string('gitlab-qa'),
    name: Matchers.string('Contract Test User'),
    suggested: Matchers.boolean(true),
  },
];

export const suggestedReviewersFixture = {
  body: Matchers.extractPayload(body),

  success: {
    status: 200,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
    },
    body,
  },

  scenario: {
    state: 'a merge request exists with suggested reviewers available for selection',
    uponReceiving: 'a request for suggested reviewers',
  },

  request: {
    withRequest: {
      method: 'GET',
      path: AUTOCOMPLETE_USERS_URL,
      query: {
        active: 'true',
        project_id: Matchers.string(TEST_PROJECT_ID),
        merge_request_iid: Matchers.string(TEST_MERGE_REQUEST_IID),
        current_user: 'true',
      },
      headers: {
        Accept: '*/*',
      },
    },
  },
};
