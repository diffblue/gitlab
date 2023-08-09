import { GlSprintf } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import Vue, { nextTick } from 'vue';
import AiGenieLoader from 'ee/ai/components/ai_genie_loader.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { i18n, GENIE_CHAT_LOADING_TRANSITION_DURATION } from 'ee/ai/constants';

Vue.use(Vuex);

describe('AiGenieLoader', () => {
  let wrapper;

  const createComponent = (
    transitionTexts = i18n.GENIE_CHAT_LOADING_TRANSITIONS,
    initialState = {},
  ) => {
    jest.spyOn(AiGenieLoader.methods, 'computeTransitionWidth').mockImplementation();

    const store = new Vuex.Store({
      state: {
        ...initialState,
      },
    });

    wrapper = shallowMountExtended(AiGenieLoader, {
      store,
      stubs: { GlSprintf },
      i18n: { ...AiGenieLoader.i18n, GENIE_CHAT_LOADING_TRANSITIONS: transitionTexts },
    });
  };

  const transition = async () => {
    jest.advanceTimersByTime(GENIE_CHAT_LOADING_TRANSITION_DURATION);
    await nextTick();
  };

  const findTransitionText = () => wrapper.vm.$refs.currentTransition[0].innerText;
  const findToolText = () => wrapper.findByTestId('tool');

  describe('rendering', () => {
    it('displays a loading message', async () => {
      createComponent(['broadcasting']);
      await nextTick();

      expect(wrapper.text()).toContain('GitLab Duo is broadcasting an answer');
    });

    it('cycles through transition texts', async () => {
      createComponent();
      await nextTick();

      expect(findTransitionText()).toEqual('finding');

      await transition();

      expect(findTransitionText()).toEqual('working on');

      await transition();

      expect(findTransitionText()).toEqual('generating');

      await transition();

      expect(findTransitionText()).toEqual('producing');
    });

    it('shows the default tool if `toolMessage` is empty', async () => {
      createComponent();
      await nextTick();

      expect(findToolText().text()).toBe(i18n.GITLAB_DUO);
    });

    it('shows the `toolMessage` if it exists in the state', async () => {
      createComponent(i18n.GENIE_CHAT_LOADING_TRANSITIONS, {
        toolMessage: { content: 'foo' },
      });
      await nextTick();

      expect(findToolText().text()).toBe('foo');
    });
  });
});
