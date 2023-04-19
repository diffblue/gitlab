import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlCollapsibleListbox, GlListboxItem, GlLoadingIcon } from '@gitlab/ui';
import { createMockSubscription } from 'mock-apollo-client';

import createMockApollo from 'helpers/mock_apollo_helper';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { updateText } from '~/lib/utils/text_markdown';

import AiActionsDropdown, {
  ACTIONS,
  MAX_REQUEST_TIMEOUT,
} from 'ee/vue_shared/components/markdown/ai_actions_dropdown.vue';
import aiResponseSubscription from 'ee/graphql_shared/subscriptions/ai_completion_response.subscription.graphql';
import aiActionMutation from 'ee/graphql_shared/mutations/ai_action.mutation.graphql';

Vue.use(VueApollo);

jest.mock('~/alert');
jest.mock('~/lib/utils/text_markdown');

describe('AI actions dropdown component', () => {
  let wrapper;
  const resourceGlobalId = 'gid://gitlab/Issue/1';
  const userId = 99;
  let aiResponseSubscriptionHandler;
  let aiActionMutationHandler;

  const findSummarizeCommentsAction = () =>
    wrapper
      .findAllComponents(GlListboxItem)
      .filter((item) => item.text().includes('Summarize comments'))
      .at(0);
  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findLoadingSpinner = () => wrapper.findComponent(GlLoadingIcon);

  const createWrapper = (props) => {
    window.gon = { current_user_id: userId };

    aiResponseSubscriptionHandler = createMockSubscription();
    aiActionMutationHandler = jest.fn();
    const mockApollo = createMockApollo([[aiActionMutation, aiActionMutationHandler]]);
    mockApollo.defaultClient.setRequestHandler(
      aiResponseSubscription,
      () => aiResponseSubscriptionHandler,
    );

    wrapper = mountExtended(AiActionsDropdown, {
      attachTo: '#root',
      apolloProvider: mockApollo,
      propsData: {
        resourceGlobalId,
        ...props,
      },
    });
  };

  beforeEach(() => {
    setHTMLFixture('<div class="md-area"><textarea></textarea><div id="root"></div></div>');
    createWrapper();
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('summarize comments action', () => {
    function selectSummariseComments() {
      findDropdown().vm.$emit('select', ACTIONS.SUMMARIZE_COMMENTS);
      return nextTick();
    }

    it('shows the summarize comments action', () => {
      expect(findSummarizeCommentsAction().exists()).toBe(true);
    });

    it('submits an AI action mutation when selecting', async () => {
      await selectSummariseComments();

      expect(aiActionMutationHandler).toHaveBeenCalledWith({
        input: { summarizeComments: { resourceId: 'gid://gitlab/Issue/1' } },
      });
    });

    it('shows loading state', async () => {
      expect(findLoadingSpinner().exists()).toBe(false);

      await selectSummariseComments();

      expect(findLoadingSpinner().exists()).toBe(true);
    });

    describe('success', () => {
      beforeEach(async () => {
        aiActionMutationHandler.mockResolvedValue({});

        await selectSummariseComments();

        aiResponseSubscriptionHandler.next({
          data: {
            aiCompletionResponse: {
              responseBody: 'yay',
            },
          },
        });
      });

      it('stops loading', () => {
        expect(findLoadingSpinner().exists()).toBe(false);
      });

      it('sets the textarea value', () => {
        expect(updateText).toHaveBeenCalledWith({
          textArea: document.querySelector('textarea'),
          tag: `yay\n***\n_This comment was generated using OpenAI_`,
          cursorOffset: 0,
          wrap: false,
        });
      });

      it('does not timeout once it has received a successful response', async () => {
        jest.advanceTimersByTime(MAX_REQUEST_TIMEOUT);
        await nextTick();

        expect(createAlert).not.toHaveBeenCalled();
      });
    });

    describe('errors', () => {
      it('shows an error when there is no response within the timeout period', async () => {
        await selectSummariseComments();

        jest.advanceTimersByTime(MAX_REQUEST_TIMEOUT);
        await nextTick();

        expect(createAlert).toHaveBeenCalledWith({
          message: 'Something went wrong',
        });
      });

      it('shows an error when the AI action mutation response contains errors', async () => {
        const errors = ['oh no', 'it didnt do the thing', 'zzzeezoo'];

        aiActionMutationHandler.mockResolvedValue({
          data: {
            aiAction: {
              errors,
            },
          },
        });

        await selectSummariseComments();
        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith(
          expect.objectContaining({
            message: errors.join(','),
            captureError: true,
            error: expect.any(Error),
          }),
        );
      });

      it('shows an error and logs to Sentry when the AI action mutation request fails', async () => {
        const mockError = new Error('ding');
        aiActionMutationHandler.mockRejectedValue(mockError);

        await selectSummariseComments();
        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith(
          expect.objectContaining({
            message: 'ding',
            captureError: true,
            error: mockError,
          }),
        );
      });

      it('shows an error and logs to Sentry when the AI subscription fails', () => {
        const mockError = new Error('ding');

        aiResponseSubscriptionHandler.error(mockError);

        expect(createAlert).toHaveBeenCalledWith(
          expect.objectContaining({
            message: 'ding',
            captureError: true,
            error: mockError,
          }),
        );
      });
    });
  });
});
