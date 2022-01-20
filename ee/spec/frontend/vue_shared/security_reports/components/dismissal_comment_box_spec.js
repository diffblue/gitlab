import { GlFormTextarea } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import component from 'ee/vue_shared/security_reports/components/dismissal_comment_box.vue';

describe('DismissalCommentBox', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = mount(component);
  });

  it('should clear the text string on mount', () => {
    // It does this by setting the input to an empty string
    expect(wrapper.emitted().input[0][0]).toBe('');
  });

  it('should clear the errors on mount', () => {
    expect(wrapper.emitted().clearError).toBeTruthy();
  });

  it('should submit the comment when cmd+enter is pressed', () => {
    wrapper.findComponent(GlFormTextarea).trigger('keydown.enter', {
      metaKey: true,
    });

    return wrapper.vm.$nextTick(() => {
      expect(wrapper.emitted().submit).toBeTruthy();
    });
  });

  it('should render the error message', () => {
    const errorMessage = 'You did something wrong';
    wrapper.setProps({ errorMessage });

    return wrapper.vm.$nextTick(() => {
      expect(wrapper.find('.js-error').text()).toBe(errorMessage);
    });
  });

  it('should render the placeholder', () => {
    const placeholder = 'Please type into the box';
    wrapper.setProps({ placeholder });

    return wrapper.vm.$nextTick(() => {
      expect(wrapper.findComponent(GlFormTextarea).attributes('placeholder')).toBe(placeholder);
    });
  });
});
