import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import SummarizeMyReview from 'ee/batch_comments/components/summarize_my_review.vue';
import aiResponseSubscription from 'ee/graphql_shared/subscriptions/ai_completion_response.subscription.graphql';
import summarizeReviewMutation from 'ee/batch_comments/graphql/summarize_review.mutation.graphql';

jest.mock('~/alert');

Vue.use(VueApollo);

let wrapper;
let subscriptionHandlerMock;
let mutationHandlerMock;

function createComponent() {
  const apolloProvider = createMockApollo([
    [aiResponseSubscription, subscriptionHandlerMock],
    [summarizeReviewMutation, mutationHandlerMock],
  ]);

  wrapper = mountExtended(SummarizeMyReview, {
    propsData: {
      id: 1,
    },
    apolloProvider,
  });
}

const findButton = () => wrapper.findByTestId('mutation-trigger');

describe('Generate test file drawer component', () => {
  beforeEach(() => {
    window.gon.current_user_id = 1;
    mutationHandlerMock = jest
      .fn()
      .mockResolvedValue({ data: { aiAction: { errors: [], __typename: 'AiActionPayload' } } });
    subscriptionHandlerMock = jest.fn().mockResolvedValue({
      data: {
        aiCompletionResponse: {
          responseBody: 'This is a summary',
          errors: [],
        },
      },
    });
  });

  afterEach(() => {
    mutationHandlerMock.mockRestore();
    subscriptionHandlerMock.mockRestore();
  });

  it('calls mutation button is clicked', async () => {
    createComponent();

    findButton().trigger('click');

    await nextTick();

    expect(mutationHandlerMock).toHaveBeenCalledWith({ resourceId: 'gid://gitlab/MergeRequest/1' });
  });

  it('emits input event when subscription returns value', async () => {
    createComponent();

    findButton().trigger('click');

    await nextTick();
    await waitForPromises();

    expect(wrapper.emitted()).toEqual({ input: [['This is a summary']] });
  });

  it('calls createAlert when subsription returns an error', async () => {
    subscriptionHandlerMock = jest.fn().mockResolvedValue({
      data: {
        aiCompletionResponse: {
          responseBody: null,
          errors: ['Error'],
        },
      },
    });

    createComponent();

    findButton().trigger('click');

    await nextTick();
    await waitForPromises();

    expect(createAlert).toHaveBeenCalledWith({ message: 'Error' });
  });
});
