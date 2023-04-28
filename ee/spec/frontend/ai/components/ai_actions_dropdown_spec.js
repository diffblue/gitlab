import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlDisclosureDropdown, GlLoadingIcon } from '@gitlab/ui';
import { createMockSubscription } from 'mock-apollo-client';

import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';

import AiActionsDropdown from 'ee/ai/components/ai_actions_dropdown.vue';
import aiResponseSubscription from 'ee/graphql_shared/subscriptions/ai_completion_response.subscription.graphql';
import { resetHTMLFixture, setHTMLFixture } from 'helpers/fixtures';
import dummyMutation from './mocks/dummy_mutation.graphql';

Vue.use(VueApollo);

jest.mock('~/alert');

describe('AI actions dropdown component', () => {
  let wrapper;
  let aiResponseSubscriptionHandler;
  let aiActionMutationHandler;

  const createActions = (handler = () => Promise.resolve("Here's the summary...")) => [
    {
      title: 'Summarize comments',
      description: 'Get a short summary of all the comments',
      handler,
    },
  ];
  const createApolloActions = () => [
    {
      title: 'Summarize comments',
      description: 'Get a short summary of all the comments',
      apolloMutation() {
        return {
          mutation: dummyMutation,
        };
      },
    },
  ];

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findLoadingSpinner = () => wrapper.findComponent(GlLoadingIcon);
  const findAction = (position = 0) =>
    wrapper.findAllByTestId('disclosure-dropdown-item').at(position);
  const clickAction = (position) => findAction(position).find('button').trigger('click');

  const createWrapper = (actions) => {
    aiResponseSubscriptionHandler = createMockSubscription();
    aiActionMutationHandler = jest.fn();
    const mockApollo = createMockApollo([[dummyMutation, aiActionMutationHandler]]);
    mockApollo.defaultClient.setRequestHandler(
      aiResponseSubscription,
      () => aiResponseSubscriptionHandler,
    );

    wrapper = mountExtended(AiActionsDropdown, {
      attachTo: '#root',
      apolloProvider: mockApollo,
      propsData: {
        actions,
      },
    });
  };

  beforeEach(() => {
    setHTMLFixture(`<div id="root"></div>`);
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('shows disclosure dropdown', () => {
    createWrapper(createActions());
    expect(findDropdown().exists()).toBe(true);
  });

  it('passes down correct actions', () => {
    const actions = createActions();
    createWrapper(actions);
    const [{ items }] = findDropdown().props('items');
    expect(items).toHaveLength(actions.length);
    expect(items[0].text).toBe(actions[0].title);
  });

  it('shows item title and description', () => {
    const actions = createActions();
    createWrapper(actions);
    const text = findAction(0).text();
    expect(text).toContain(actions[0].title);
    expect(text).toContain(actions[0].description);
  });

  describe('abstract actions', () => {
    const createWithAsyncHandler = () => {
      const result = {};
      const handler = () =>
        new Promise((resolve, reject) => {
          result.res = resolve;
          result.rej = reject;
        });
      createWrapper(createActions(handler));
      return result;
    };

    it('shows loading state', async () => {
      const handler = createWithAsyncHandler();
      await clickAction();
      expect(findLoadingSpinner().exists()).toBe(true);
      handler.res();
    });

    it('hides loading state on success', async () => {
      const handler = createWithAsyncHandler();
      await clickAction();
      handler.res();
      await waitForPromises();
      expect(findLoadingSpinner().exists()).toBe(false);
    });

    it('emits input event on success', async () => {
      const response = 'FooBar';
      const handler = createWithAsyncHandler();
      await clickAction();
      handler.res(response);
      await waitForPromises();
      expect(wrapper.emitted('input')).toStrictEqual([[response]]);
    });

    it('hides loading state on fail', async () => {
      const handler = createWithAsyncHandler();
      await clickAction();
      handler.rej();
      await waitForPromises();
      expect(findLoadingSpinner().exists()).toBe(false);
    });

    it('shows error on fail', async () => {
      const message = 'FooBar';
      const handler = createWithAsyncHandler();
      await clickAction();
      handler.rej(new Error(message));
      await waitForPromises();
      expect(createAlert).toHaveBeenCalledWith(
        expect.objectContaining({
          message,
          captureError: true,
          error: expect.any(Error),
        }),
      );
    });
  });

  describe('apollo actions', () => {
    beforeEach(() => {
      createWrapper(createApolloActions());
    });

    it('emits response from action', async () => {
      const responseBody = 'FooBar';

      aiResponseSubscriptionHandler.next({
        data: {
          aiCompletionResponse: {
            responseBody,
          },
        },
      });

      await clickAction();
      await waitForPromises();

      expect(wrapper.emitted('input')).toStrictEqual([[responseBody]]);
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

      await clickAction();
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

      await clickAction();
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
