import { GlSprintf, GlFormTextarea, GlLink, GlButton } from '@gitlab/ui';
import Vue from 'vue';
import Vuex from 'vuex';
import { ENTER_KEY } from '~/lib/utils/keys';
import TanukiBotChatInput from 'ee/ai/tanuki_bot/components/tanuki_bot_chat_input.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { MOCK_USER_MESSAGE } from '../mock_data';

Vue.use(Vuex);

describe('TanukiBotChatInput', () => {
  let wrapper;

  const createComponent = (initialState) => {
    const store = new Vuex.Store({
      state: {
        loading: false,
        ...initialState,
      },
    });

    wrapper = shallowMountExtended(TanukiBotChatInput, {
      store,
      stubs: {
        GlSprintf,
      },
    });
  };

  const findGlFormTextarea = () => wrapper.findComponent(GlFormTextarea);
  const findGlButton = () => wrapper.findComponent(GlButton);
  const findGlLink = () => wrapper.findComponent(GlLink);

  describe('when not loading', () => {
    beforeEach(() => {
      createComponent();
    });

    it('can send message via pressing Enter on the text field', () => {
      findGlFormTextarea().vm.$emit('input', MOCK_USER_MESSAGE.msg);
      findGlFormTextarea().vm.$emit('keydown', new KeyboardEvent({ key: ENTER_KEY }));

      expect(wrapper.emitted('submit')).toStrictEqual([[MOCK_USER_MESSAGE.msg]]);
    });

    it('can send message via pressing Send button', () => {
      findGlFormTextarea().vm.$emit('input', MOCK_USER_MESSAGE.msg);
      findGlButton().vm.$emit('click');

      expect(wrapper.emitted('submit')).toStrictEqual([[MOCK_USER_MESSAGE.msg]]);
    });

    it('can send message via pressing "what is a fork?" link', () => {
      findGlFormTextarea().vm.$emit('input', MOCK_USER_MESSAGE.msg);
      findGlLink().vm.$emit('click');

      expect(wrapper.emitted('submit')).toStrictEqual([['What is a fork?']]);
    });
  });

  describe('when loading', () => {
    beforeEach(() => {
      createComponent({ loading: true });
    });

    it('can not send message via pressing Enter on the text field', () => {
      findGlFormTextarea().vm.$emit('input', MOCK_USER_MESSAGE.msg);
      findGlFormTextarea().vm.$emit('keydown', new KeyboardEvent({ key: ENTER_KEY }));

      expect(wrapper.emitted('submit')).toBeUndefined();
    });

    it('can not send message via pressing Send button', () => {
      findGlFormTextarea().vm.$emit('input', MOCK_USER_MESSAGE.msg);
      findGlButton().vm.$emit('click');

      expect(wrapper.emitted('submit')).toBeUndefined();
    });

    it('can not send message via pressing "what is a fork?" link', () => {
      findGlFormTextarea().vm.$emit('input', MOCK_USER_MESSAGE.msg);
      findGlLink().vm.$emit('click');

      expect(wrapper.emitted('submit')).toBeUndefined();
    });
  });
});
