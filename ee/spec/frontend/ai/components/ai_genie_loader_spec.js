import { GlSprintf } from '@gitlab/ui';
import { nextTick } from 'vue';
import AiGenieLoader from 'ee/ai/components/ai_genie_loader.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { i18n, GENIE_CHAT_LOADING_TRANSITION_DURATION } from 'ee/ai/constants';

describe('AiGenieLoader', () => {
  let wrapper;

  const createComponent = (transitionTexts = i18n.GENIE_CHAT_LOADING_TRANSITIONS) => {
    jest.spyOn(AiGenieLoader.methods, 'computeTransitionWidth').mockImplementation();

    wrapper = shallowMountExtended(AiGenieLoader, {
      stubs: { GlSprintf },
      i18n: { ...AiGenieLoader.i18n, GENIE_CHAT_LOADING_TRANSITIONS: transitionTexts },
    });
  };

  const transition = async () => {
    jest.advanceTimersByTime(GENIE_CHAT_LOADING_TRANSITION_DURATION);
    await nextTick();
  };

  const findTransitionText = () => wrapper.vm.$refs.currentTransition[0].innerText;

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
  });
});
