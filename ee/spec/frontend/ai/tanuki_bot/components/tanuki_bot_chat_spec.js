import { GlLoadingIcon } from '@gitlab/ui';
import Vue from 'vue';
import Vuex from 'vuex';
import TanukiBotChat from 'ee/ai/tanuki_bot/components/tanuki_bot_chat.vue';
import TanukiBotChatMessages from 'ee/ai/tanuki_bot/components/tanuki_bot_chat_message.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { MOCK_USER_MESSAGE, MOCK_TANUKI_MESSAGE } from '../mock_data';

Vue.use(Vuex);

describe('TanukiBotChat', () => {
  let wrapper;

  const defaultState = {
    loading: false,
    messages: [],
  };

  const createComponent = (initialState) => {
    const store = new Vuex.Store({
      state: {
        ...defaultState,
        ...initialState,
      },
    });

    wrapper = shallowMountExtended(TanukiBotChat, {
      store,
    });
  };

  const findTanukiBotChatMessages = () => wrapper.findAllComponents(TanukiBotChatMessages);
  const findGlLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  describe('GlLoadingIcon', () => {
    it.each([true, false])('when loading is "%s" it renders/does not render"', (loading) => {
      createComponent({ loading });
      expect(findGlLoadingIcon().exists()).toBe(loading);
    });
  });

  describe('TanukiBotChatMessages', () => {
    beforeEach(() => {
      createComponent({ messages: [MOCK_USER_MESSAGE, MOCK_TANUKI_MESSAGE] });
    });

    it('renders for each message', () => {
      expect(findTanukiBotChatMessages().length).toBe(2);
      expect(findTanukiBotChatMessages().wrappers.map((w) => w.props('message'))).toStrictEqual([
        MOCK_USER_MESSAGE,
        MOCK_TANUKI_MESSAGE,
      ]);
    });
  });
});
