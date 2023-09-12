import { nextTick } from 'vue';
import { GlButton } from '@gitlab/ui';
import DuoChatFeedbackModal from 'ee/ai/components/duo_chat_feedback_modal.vue';
import Tracking from '~/tracking';
import { EXPLAIN_CODE_TRACKING_EVENT_NAME, i18n } from 'ee/ai/constants';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import UserFeedback from 'ee/ai/components/user_feedback.vue';

describe('UserFeedback', () => {
  let wrapper;

  const promptLocation = 'before_content';
  const createComponent = ({ props, data = {} } = {}) => {
    wrapper = shallowMountExtended(UserFeedback, {
      data() {
        return data;
      },
      propsData: {
        eventName: EXPLAIN_CODE_TRACKING_EVENT_NAME,
        promptLocation,
        ...props,
      },
    });
  };

  const findButtons = () => wrapper.findAllComponents(GlButton);
  const firstButton = () => wrapper.findAllComponents(GlButton).at(0);
  const findModal = () => wrapper.findComponent(DuoChatFeedbackModal);

  beforeEach(() => {
    jest.spyOn(Tracking, 'event');
    createComponent();
  });

  afterEach(() => {
    jest.resetAllMocks();
  });

  describe('rendering with no feedback registered', () => {
    it('renders a button to provide feedback', () => {
      expect(firstButton().exists()).toBe(true);
    });

    it('renders the feedback modal', () => {
      expect(findModal().exists()).toBe(true);
    });
  });

  describe('tracking', () => {
    const passedfeedback = { feedbackOptions: ['helpful'], extendedFeedback: 'Foo bar' };

    it('passes the feedback options to tracking when the modal emits', () => {
      findModal().vm.$emit('feedback-submitted', passedfeedback);
      expect(Tracking.event).toHaveBeenCalledWith(
        undefined,
        EXPLAIN_CODE_TRACKING_EVENT_NAME,
        expect.objectContaining({
          property: passedfeedback.feedbackOptions,
          extra: expect.objectContaining({
            extendedFeedback: passedfeedback.extendedFeedback,
          }),
        }),
      );
    });

    it('renders the thank you text instead of a button', async () => {
      findModal().vm.$emit('feedback-submitted', passedfeedback);
      await nextTick();
      expect(findButtons().length).toBe(0);
      expect(wrapper.text()).toContain(i18n.GENIE_CHAT_FEEDBACK_THANKS);
    });

    it('does not render the modal', async () => {
      findModal().vm.$emit('feedback-submitted', passedfeedback);
      await nextTick();
      expect(findModal().exists()).toBe(false);
    });

    it('fires tracking event with extra data passed from prop', () => {
      const eventExtraData = { foo: 'bar' };

      createComponent({ props: { eventName: EXPLAIN_CODE_TRACKING_EVENT_NAME, eventExtraData } });
      findModal().vm.$emit('feedback-submitted', passedfeedback);

      expect(Tracking.event).toHaveBeenCalledWith(
        undefined,
        EXPLAIN_CODE_TRACKING_EVENT_NAME,
        expect.objectContaining({
          extra: expect.objectContaining(eventExtraData),
        }),
      );
    });
  });
});
