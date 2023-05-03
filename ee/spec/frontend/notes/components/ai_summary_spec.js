import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { createMockSubscription } from 'mock-apollo-client';
import { GlIcon } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import AiSummary from 'ee/notes/components/ai_summary.vue';
import { getMarkdown } from '~/rest_api';
import waitForPromises from 'helpers/wait_for_promises';
import aiResponseSubscription from 'ee/graphql_shared/subscriptions/ai_completion_response.subscription.graphql';

Vue.use(VueApollo);
jest.mock('~/rest_api');

describe('AiSummary component', () => {
  let wrapper;
  let aiResponseSubscriptionHandler;
  const resourceGlobalId = 'gid://gitlab/Issue/1';
  const userId = 99;

  const findMarkdownRef = () => wrapper.findComponent({ ref: 'markdown' });
  const findIcon = () => wrapper.findComponent(GlIcon);

  const createWrapper = () => {
    window.gon = { current_user_id: userId };

    aiResponseSubscriptionHandler = createMockSubscription();
    const mockApollo = createMockApollo();
    mockApollo.defaultClient.setRequestHandler(
      aiResponseSubscription,
      () => aiResponseSubscriptionHandler,
    );

    wrapper = mountExtended(AiSummary, {
      apolloProvider: mockApollo,
      provide: {
        resourceGlobalId,
      },
    });
  };

  beforeEach(async () => {
    getMarkdown.mockResolvedValueOnce({ data: { html: 'yes' } });
    createWrapper();
    await waitForPromises();

    aiResponseSubscriptionHandler.next({
      data: {
        aiCompletionResponse: {
          responseBody: 'yay',
        },
      },
    });
  });

  it('shows the response in a markdown block', () => {
    expect(findMarkdownRef().text()).toContain('yes');
    expect(findIcon().exists()).toBe(true);
  });
});
