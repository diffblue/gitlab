import { GlButton, GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { createMockSubscription } from 'mock-apollo-client';
import '~/lib/utils/autosave';
import { BV_HIDE_TOOLTIP } from '~/lib/utils/constants';
import createMockApollo from 'helpers/mock_apollo_helper';
import aiActionMutation from 'ee/graphql_shared/mutations/ai_action.mutation.graphql';
import aiResponseSubscription from 'ee/graphql_shared/subscriptions/ai_completion_response.subscription.graphql';
import ConvertDescriptionModal from 'ee/issues/show/components/convert_description_modal.vue';
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
  const content = 'My issue descirption';
  const LONGER_THAN_MAX_REQUEST_TIMEOUT = 1000 * 21; // 21 seconds

  const findModal = () => wrapper.findComponent(GlModal);
  const openModal = () => wrapper.findComponent(GlButton).vm.$emit('click');
  const clickSubmit = () => findModal().vm.$emit('primary', mockEvent);
  const findError = () => wrapper.find('[data-testid="convert-description-modal-error"]');

  function openModalAndEnterDescription() {
    openModal();

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
    let bsTooltipHide;

    beforeEach(async () => {
      createWrapper({ descriptionTemplateName });

      bsTooltipHide = jest.fn();
      wrapper.vm.$root.$on(BV_HIDE_TOOLTIP, bsTooltipHide);
      aiActionMutationHandler.mockResolvedValue({ data: { aiAction: { errors: [] } } });

      await openModalAndEnterDescription();
    });

    it('closes tooltip', () => {
      expect(bsTooltipHide).toHaveBeenCalled();
    });

    it('calls the aiActionMutation', () => {
      expect(aiActionMutationHandler).toHaveBeenCalledWith({
        input: {
          generateDescription: {
            resourceId,
            content,
            descriptionTemplateName,
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

      expect(findError().text()).toBe('Error: GraphQL Error');
    });
  });

  describe('subscription response', () => {
    const descriptionTemplateName = 'Bug template';
    let bsTooltipHide;

    it('emits contentGenerated event', async () => {
      createWrapper({ descriptionTemplateName });

      bsTooltipHide = jest.fn();
      wrapper.vm.$root.$on(BV_HIDE_TOOLTIP, bsTooltipHide);
      aiActionMutationHandler.mockResolvedValue({ data: { aiAction: { errors: [] } } });

      await openModalAndEnterDescription();

      aiResponseSubscriptionHandler.next({
        data: {
          aiCompletionResponse: {
            responseBody: 'yay',
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
