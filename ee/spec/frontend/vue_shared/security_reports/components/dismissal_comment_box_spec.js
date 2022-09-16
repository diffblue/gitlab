import { GlFormTextarea } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
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
    expect(wrapper.emitted().clearError).toHaveLength(1);
  });

  it('should submit the comment when cmd+enter is pressed', async () => {
    wrapper.findComponent(GlFormTextarea).trigger('keydown.enter', {
      metaKey: true,
    });

    await nextTick();
    expect(wrapper.emitted().submit).toHaveLength(1);
  });

  it('should render the error message', async () => {
    const errorMessage = 'You did something wrong';
    wrapper.setProps({ errorMessage });

    await nextTick();
    expect(wrapper.find('.js-error').text()).toBe(errorMessage);
  });

  it('should render the placeholder', async () => {
    const placeholder = 'Please type into the box';
    wrapper.setProps({ placeholder });

    await nextTick();
    expect(wrapper.findComponent(GlFormTextarea).attributes('placeholder')).toBe(placeholder);
  });
});
