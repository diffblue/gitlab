import { GlModal, GlFormCheckboxGroup, GlFormCheckbox, GlFormTextarea, GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import FeedbackModal, { feedbackOptions } from 'ee/ai/components/duo_chat_feedback_modal.vue';

describe('FeedbackModal', () => {
  let wrapper;

  const findModal = () => wrapper.findComponent(GlModal);
  const findOptions = () => wrapper.findByTestId('feedback-options');
  const findOptionsCheckboxes = () => findOptions().findAllComponents(GlFormCheckbox);
  const findTextarea = () => wrapper.findComponent(GlFormTextarea);
  const findButtons = () => wrapper.findAllComponents(GlButton);
  const selectOption = (index = 0) => {
    wrapper
      .findAllComponents(GlFormCheckboxGroup)
      .at(index)
      .vm.$emit('input', [feedbackOptions[index].value]);
  };

  beforeEach(() => {
    wrapper = shallowMountExtended(FeedbackModal, {
      stubs: {
        GlModal,
        GlFormCheckboxGroup,
      },
    });
  });

  it('renders the feedback options', () => {
    const checkboxes = findOptionsCheckboxes();
    feedbackOptions.forEach((option, index) => {
      expect(checkboxes.at(index).text()).toBe(option.text);
      expect(checkboxes.at(index).attributes('value')).toBe(option.value);
    });
  });

  it('renders the textarea field for additional feedback', () => {
    expect(findTextarea().exists()).toBe(true);
  });

  it('renders correct buttons, incl. a button to submit the feedback', () => {
    expect(findButtons()).toHaveLength(2);
    expect(findButtons().at(0).text()).toBe('Cancel');
    expect(findButtons().at(1).text()).toBe('Submit');
  });

  describe('interaction', () => {
    it('emits the feedback event when the submit button is clicked', () => {
      selectOption();
      findModal().vm.$emit('primary');
      expect(wrapper.emitted('feedback-submitted')).toEqual([
        [
          {
            feedbackOptions: [feedbackOptions[0].value],
            extendedFeedback: '',
          },
        ],
      ]);
    });
    it('does not emit event if there is no option selected', () => {
      findModal().vm.$emit('primary');
      expect(wrapper.emitted('feedback-submitted')).toBeUndefined();
    });
  });
});
