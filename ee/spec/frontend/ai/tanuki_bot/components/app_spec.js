import { GlDrawer } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import TanukiBotChatApp from 'ee/ai/tanuki_bot/components/app.vue';
import TanukiBotChat from 'ee/ai/tanuki_bot/components/tanuki_bot_chat.vue';
import TanukiBotChatInput from 'ee/ai/tanuki_bot/components/tanuki_bot_chat_input.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { helpCenterState } from '~/super_sidebar/constants';
import { MOCK_USER_MESSAGE } from '../mock_data';

Vue.use(Vuex);

describe('TanukiBotChatApp', () => {
  let wrapper;

  const actionSpies = {
    sendMessage: jest.fn(),
  };

  const createComponent = () => {
    const store = new Vuex.Store({
      actions: actionSpies,
    });

    wrapper = shallowMountExtended(TanukiBotChatApp, {
      store,
      stubs: {
        GlDrawer,
      },
    });
  };

  const findGlDrawer = () => wrapper.findComponent(GlDrawer);
  const findGlDrawerBackdrop = () => wrapper.findByTestId('tanuki-bot-chat-drawer-backdrop');
  const findTanukiBotChat = () => wrapper.findComponent(TanukiBotChat);
  const findTanukiBotChatInput = () => wrapper.findComponent(TanukiBotChatInput);

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

    it('calls sendMessage when input is submitted', () => {
      findTanukiBotChatInput().vm.$emit('submit', MOCK_USER_MESSAGE.msg);

      expect(actionSpies.sendMessage).toHaveBeenCalledWith(
        expect.any(Object),
        MOCK_USER_MESSAGE.msg,
      );
    });
  });
});
