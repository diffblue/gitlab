import { GlButton, GlSkeletonLoader } from '@gitlab/ui';
import { nextTick } from 'vue';
import Tracking from '~/tracking';
import { FEEDBACK_OPTIONS } from 'ee/ai/constants';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import UserFeedback from 'ee/ai/components/user_feedback.vue';

describe('UserFeedback', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(UserFeedback, {
      propsData: {
        ...props,
      },
    });
  };

  const findButtons = () => wrapper.findAllComponents(GlButton);
  const firstButton = () => wrapper.findAllComponents(GlButton).at(0);
  const findSkeleton = () => wrapper.findAllComponents(GlSkeletonLoader);

  beforeEach(() => {
    createComponent();
    jest.spyOn(Tracking, 'event');
  });

  it('renders buttons based on provideed options', () => {
    expect(findButtons()).toHaveLength(FEEDBACK_OPTIONS.length);
  });

  describe('button', () => {
    it('has correct text', () => {
      expect(firstButton().text()).toBe(FEEDBACK_OPTIONS[0].title);
    });

    it('receives correct icon prop', () => {
      expect(firstButton().props('icon')).toBe(FEEDBACK_OPTIONS[0].icon);
    });

    it('does not render skeleton with the default props', () => {
      expect(findSkeleton().exists()).toBe(false);
    });

    it('renders sekeleton loader id isLoading prop is set to true', () => {
      createComponent({ isLoading: true });
      expect(findSkeleton().exists()).toBe(true);
    });
  });

  describe('tracking', () => {
    it('fires tracking event  when component is destroyed if button was clicked', () => {
      firstButton().vm.$emit('click');

      expect(Tracking.event).toHaveBeenCalledWith(undefined, 'explain_code_blob_viewer', {
        action: 'click_button',
        extra: { prompt_location: 'before_content' },
        label: 'response_feedback',
        property: FEEDBACK_OPTIONS[0].value,
      });
    });

    it('fires tracking event when the window is closed', () => {
      firstButton().vm.$emit('click');

      expect(Tracking.event).toHaveBeenCalledWith(undefined, 'explain_code_blob_viewer', {
        action: 'click_button',
        extra: { prompt_location: 'before_content' },
        label: 'response_feedback',
        property: FEEDBACK_OPTIONS[0].value,
      });
    });

    it('shows only selected option with disabled state once feedback is provided', async () => {
      const selectedButtonIndex = 2;
      findButtons().at(selectedButtonIndex).vm.$emit('click');
      await nextTick();
      expect(findButtons()).toHaveLength(1);
      expect(firstButton().attributes('disabled')).toBe('true');
      expect(firstButton().text()).toBe(FEEDBACK_OPTIONS[selectedButtonIndex].title);
    });
  });
});
