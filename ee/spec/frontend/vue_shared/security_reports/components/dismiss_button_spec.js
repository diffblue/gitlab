import { GlButton } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import component from 'ee/vue_shared/security_reports/components/dismiss_button.vue';

describe('DismissalButton', () => {
  let wrapper;

  const mountComponent = (options) => {
    wrapper = mount(component, options);
  };

  describe('With a non-dismissed vulnerability', () => {
    beforeEach(() => {
      const propsData = {
        isDismissed: false,
      };
      mountComponent({ propsData });
    });

    it('should render the dismiss button', () => {
      expect(wrapper.text()).toBe('Dismiss vulnerability');
    });

    it('should emit dismiss vulnerability when clicked', async () => {
      wrapper.findComponent(GlButton).trigger('click');
      await nextTick();
      expect(wrapper.emitted().dismissVulnerability).toBeDefined();
    });

    it('should render the dismiss with comment button', () => {
      expect(wrapper.find('.js-dismiss-with-comment').exists()).toBe(true);
    });

    it('should emit openDismissalCommentBox when clicked', async () => {
      wrapper.find('.js-dismiss-with-comment').trigger('click');
      await nextTick();
      expect(wrapper.emitted().openDismissalCommentBox).toBeDefined();
    });
  });

  describe('with a dismissed vulnerability', () => {
    beforeEach(() => {
      const propsData = {
        isDismissed: true,
      };
      mountComponent({ propsData });
    });

    it('should render the undo dismiss button', () => {
      expect(wrapper.text()).toBe('Undo dismiss');
    });

    it('should emit revertDismissVulnerability when clicked', async () => {
      wrapper.findComponent(GlButton).trigger('click');
      await nextTick();
      expect(wrapper.emitted().revertDismissVulnerability).toBeDefined();
    });

    it('should not render the dismiss with comment button', () => {
      expect(wrapper.find('.js-dismiss-with-comment').exists()).toBe(false);
    });
  });
});
