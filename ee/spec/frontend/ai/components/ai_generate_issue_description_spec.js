import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { createMockSubscription } from 'mock-apollo-client';
import '~/lib/utils/autosave';
import createMockApollo from 'helpers/mock_apollo_helper';
import aiActionMutation from 'ee/graphql_shared/mutations/ai_action.mutation.graphql';
import aiResponseSubscription from 'ee/graphql_shared/subscriptions/ai_completion_response.subscription.graphql';
import ConvertDescriptionModal from 'ee/ai/components/ai_generate_issue_description.vue';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import waitForPromises from 'helpers/wait_for_promises';

Vue.use(VueApollo);
jest.mock('~/lib/utils/autosave');

const mockEvent = { preventDefault: jest.fn() };

describe('Convert description', () => {
  let wrapper;
  let aiActionMutationHandler;
  let aiResponseSubscriptionHandler;
  const userId = 123;
  const resourceId = 'gid://gitlab/Issue/1';
  const content = 'My issue description';
  const LONGER_THAN_MAX_REQUEST_TIMEOUT = 1000 * 31;

  const findModal = () => wrapper.findComponent(GlModal);
  const clickSubmit = () => findModal().vm.$emit('primary', mockEvent);
  const findError = () => wrapper.find('[data-testid="convert-description-modal-error"]');

  function openModalAndEnterDescription() {
    wrapper.find('textarea').setValue(content);

    clickSubmit();
  }

  const createWrapper = ({ props, descriptionTemplateName } = {}) => {
    window.gon = { current_user_id: userId };

    aiActionMutationHandler = jest.fn();
    aiResponseSubscriptionHandler = createMockSubscription();
    const mockApollo = createMockApollo([[aiActionMutation, aiActionMutationHandler]]);
    mockApollo.defaultClient.setRequestHandler(
      aiResponseSubscription,
      () => aiResponseSubscriptionHandler,
    );

    setHTMLFixture(
      `<select class="js-issuable-selector">${descriptionTemplateName}</select><div class="js-attach-to"></div>`,
    );

    wrapper = shallowMount(ConvertDescriptionModal, {
      apolloProvider: mockApollo,
      propsData: {
        resourceId,
        ...props,
      },
      stubs: { GlModal },
      attachTo: '.js-attach-to',
    });
  };

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('successful mutation', () => {
    const descriptionTemplateName = 'Bug template';

    beforeEach(async () => {
      createWrapper({ descriptionTemplateName });

      aiActionMutationHandler.mockResolvedValue({ data: { aiAction: { errors: [] } } });

      await openModalAndEnterDescription();
    });

    it('calls the aiActionMutation', () => {
      expect(aiActionMutationHandler).toHaveBeenCalledWith({
        input: {
          generateDescription: {
            resourceId,
            content,
          },
        },
      });
    });

    it('does not timeout once it has received a successful response', async () => {
      await waitForPromises();
      jest.advanceTimersByTime(LONGER_THAN_MAX_REQUEST_TIMEOUT);

      expect(findError().exists()).toBe(false);
    });
  });

  describe('unsuccessful mutation', () => {
    beforeEach(() => {
      createWrapper();
      aiActionMutationHandler.mockResolvedValue({
        data: { aiAction: { errors: ['GraphQL Error'] } },
      });

      openModalAndEnterDescription();
    });

    it('shows error if no response within timeout limit', async () => {
      jest.advanceTimersByTime();
      await nextTick();

      expect(findError().text()).toBe('Failed to generate description');
    });

    it('shows error on error response', async () => {
      await waitForPromises();

      expect(findError().text()).toBe('GraphQL Error');
    });
  });

  describe('subscription response', () => {
    const descriptionTemplateName = 'Bug template';

    it('emits contentGenerated event', async () => {
      createWrapper({ descriptionTemplateName });

      aiActionMutationHandler.mockResolvedValue({ data: { aiAction: { errors: [] } } });

      await openModalAndEnterDescription();

      aiResponseSubscriptionHandler.next({
        data: {
          aiCompletionResponse: {
            content: 'yay',
          },
        },
      });

      expect(wrapper.emitted('contentGenerated')).toEqual([
        [
          `yay

***
_Description was generated using AI_`,
        ],
      ]);
    });
  });
});
