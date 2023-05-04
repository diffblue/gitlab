import { GlDrawer } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import VueApollo from 'vue-apollo';
import TanukiBotChatApp from 'ee/ai/tanuki_bot/components/app.vue';
import TanukiBotChat from 'ee/ai/tanuki_bot/components/tanuki_bot_chat.vue';
import TanukiBotChatInput from 'ee/ai/tanuki_bot/components/tanuki_bot_chat_input.vue';
import aiResponseSubscription from 'ee/graphql_shared/subscriptions/ai_completion_response.subscription.graphql';
import tanukiBotMutation from 'ee/ai/graphql/tanuki_bot.mutation.graphql';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import { helpCenterState } from '~/super_sidebar/constants';
import {
  MOCK_USER_MESSAGE,
  MOCK_USER_ID,
  MOCK_TANUKI_SUCCESS_RES,
  MOCK_TANUKI_BOT_MUTATATION_RES,
} from '../mock_data';

Vue.use(Vuex);
Vue.use(VueApollo);

describe('TanukiBotChatApp', () => {
  let wrapper;

  const actionSpies = {
    sendUserMessage: jest.fn(),
    receiveTanukiBotMessage: jest.fn(),
    tanukiBotMessageError: jest.fn(),
  };

  let subscriptionHandlerMock = jest.fn().mockResolvedValue(MOCK_TANUKI_SUCCESS_RES);
  let mutationHandlerMock = jest.fn().mockResolvedValue(MOCK_TANUKI_BOT_MUTATATION_RES);

  const createComponent = () => {
    const store = new Vuex.Store({
      actions: actionSpies,
    });

    const apolloProvider = createMockApollo([
      [aiResponseSubscription, subscriptionHandlerMock],
      [tanukiBotMutation, mutationHandlerMock],
    ]);

    wrapper = shallowMountExtended(TanukiBotChatApp, {
      store,
      apolloProvider,
      propsData: {
        userId: MOCK_USER_ID,
      },
      stubs: {
        GlDrawer,
      },
    });
  };

  const findGlDrawer = () => wrapper.findComponent(GlDrawer);
  const findGlDrawerBackdrop = () => wrapper.findByTestId('tanuki-bot-chat-drawer-backdrop');
  const findTanukiBotChat = () => wrapper.findComponent(TanukiBotChat);
  const findTanukiBotChatInput = () => wrapper.findComponent(TanukiBotChatInput);
  const findWarning = () => wrapper.findByTestId('chat-legal-warning');

  describe('rendering', () => {
    beforeEach(() => {
      createComponent();
      helpCenterState.showTanukiBotChatDrawer = true;
    });

    it('renders a legal info when rendered', () => {
      expect(findWarning().exists()).toBe(true);
    });
  });

  describe('GlDrawer interactions', () => {
    beforeEach(() => {
      createComponent();
      helpCenterState.showTanukiBotChatDrawer = true;
    });

    it('closes the drawer when GlDrawer emits @close', async () => {
      findGlDrawer().vm.$emit('close');

      await nextTick();

      expect(findGlDrawer().props('open')).toBe(false);
    });
  });

  describe('GlDrawer Backdrop', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not render when drawer is closed', () => {
      expect(findGlDrawerBackdrop().exists()).toBe(false);
    });

    describe('when open is true', () => {
      beforeEach(() => {
        createComponent();
        helpCenterState.showTanukiBotChatDrawer = true;
      });

      it('does render', () => {
        expect(findGlDrawerBackdrop().exists()).toBe(true);
      });

      it('when clicked, calls closeDrawer', async () => {
        findGlDrawerBackdrop().trigger('click');

        await nextTick();

        expect(findGlDrawer().props('open')).toBe(false);
      });
    });
  });

  describe('Tanuki Chat', () => {
    beforeEach(() => {
      createComponent();
      helpCenterState.showTanukiBotChatDrawer = true;
    });

    it('renders TanukiBotChat', () => {
      expect(findTanukiBotChat().exists()).toBe(true);
    });

    describe('when input is submitted', () => {
      beforeEach(() => {
        findTanukiBotChatInput().vm.$emit('submit', MOCK_USER_MESSAGE.msg);
      });

      it('calls sendUserMessage when input is submitted', () => {
        expect(actionSpies.sendUserMessage).toHaveBeenCalledWith(
          expect.any(Object),
          MOCK_USER_MESSAGE.msg,
        );
      });

      it('calls GraphQL mutation when input is submitted', () => {
        expect(mutationHandlerMock).toHaveBeenCalledWith({
          resourceId: MOCK_USER_ID,
          question: MOCK_USER_MESSAGE.msg,
        });
      });

      it('once response arrives via GraphQL subscription calls receiveTanukiBotMessage', () => {
        expect(subscriptionHandlerMock).toHaveBeenCalledWith({
          resourceId: MOCK_USER_ID,
          userId: MOCK_USER_ID,
        });
        expect(actionSpies.receiveTanukiBotMessage).toHaveBeenCalledWith(
          expect.any(Object),
          MOCK_TANUKI_SUCCESS_RES.data,
        );
      });
    });
  });

  describe('Error conditions', () => {
    describe('when subscription fails', () => {
      beforeEach(async () => {
        subscriptionHandlerMock = jest.fn().mockRejectedValue({ errors: [] });
        createComponent();

        helpCenterState.showTanukiBotChatDrawer = true;
        await nextTick();
        findTanukiBotChatInput().vm.$emit('submit', MOCK_USER_MESSAGE.msg);
      });

      it('once error arrives via GraphQL subscription calls tanukiBotMessageError', () => {
        expect(subscriptionHandlerMock).toHaveBeenCalledWith({
          resourceId: MOCK_USER_ID,
          userId: MOCK_USER_ID,
        });
        expect(actionSpies.tanukiBotMessageError).toHaveBeenCalled();
      });
    });

    describe('when mutation fails', () => {
      beforeEach(async () => {
        mutationHandlerMock = jest.fn().mockRejectedValue();
        createComponent();

        helpCenterState.showTanukiBotChatDrawer = true;
        await nextTick();
        findTanukiBotChatInput().vm.$emit('submit', MOCK_USER_MESSAGE.msg);
      });

      it('calls tanukiBotMessageError', () => {
        expect(actionSpies.tanukiBotMessageError).toHaveBeenCalled();
      });
    });
  });
});
