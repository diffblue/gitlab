import path from 'path';
import { pactWith } from 'jest-pact';
import { suggestedReviewersFixture } from '../../../fixtures/project/merge_requests/suggested_reviewers.fixture';
import { getSuggestedReviewers } from '../../../resources/api/project/autocomplete_users';

const ROOT_PATH = path.resolve(__dirname, '../../..');
const CONSUMER_NAME = 'MergeRequests#show';
const CONSUMER_LOG = path.join(ROOT_PATH, '../logs/consumer.log');
const CONTRACT_DIR = path.join(ROOT_PATH, '../contracts/project/merge_requests/show');
const SUGGESTED_REVIEWERS_PROVIDER_NAME = 'GET suggested reviewers';

// API endpoint: /autocomplete/users.json
pactWith(
  {
    consumer: CONSUMER_NAME,
    provider: SUGGESTED_REVIEWERS_PROVIDER_NAME,
    log: CONSUMER_LOG,
    dir: CONTRACT_DIR,
  },

  (provider) => {
    describe(SUGGESTED_REVIEWERS_PROVIDER_NAME, () => {
      beforeEach(() => {
        const interaction = {
          ...suggestedReviewersFixture.scenario,
          ...suggestedReviewersFixture.request,
          willRespondWith: suggestedReviewersFixture.success,
        };
        provider.addInteraction(interaction);
      });

      it('return a successful body', async () => {
        const suggestedReviewers = await getSuggestedReviewers({
          url: provider.mockService.baseUrl,
        });

        expect(suggestedReviewers).toEqual(suggestedReviewersFixture.body);
      });
    });
  },
);
