import { mount } from '@vue/test-utils';
import DismissalCommentBox from 'ee/vue_shared/security_reports/components/dismissal_comment_box.vue';
import component from 'ee/vue_shared/security_reports/components/dismissal_comment_box_toggle.vue';

describe('DismissalCommentBox', () => {
  let wrapper;

  describe('when the box is inactive', () => {
    beforeEach(() => {
      wrapper = mount(component);
    });

    it('should render the placeholder text box', () => {
      expect(wrapper.find('.js-comment-placeholder').exists()).toBe(true);
    });

    it('should not render the dismissal comment box', () => {
      expect(wrapper.findComponent(DismissalCommentBox).exists()).toBe(false);
    });
  });

  describe('when the box is active', () => {
    beforeEach(() => {
      wrapper = mount(component, {
        propsData: {
          isActive: true,
        },
      });
    });

    it('should render the dismissal comment box', () => {
      expect(wrapper.findComponent(DismissalCommentBox).exists()).toBe(true);
    });

    it('should not render the placeholder text box', () => {
      expect(wrapper.find('.js-comment-placeholder').exists()).toBe(false);
    });
  });
});
