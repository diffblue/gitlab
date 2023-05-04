import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import FormStatus from 'ee/groups/settings/compliance_frameworks/components/form_status.vue';

describe('FormStatus', () => {
  let wrapper;

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findDefaultSlot = () => wrapper.find('[data-testid="default-slot"]');

  function createComponent(props = {}) {
    return shallowMount(FormStatus, {
      propsData: {
        ...props,
      },
      slots: {
        default: '<span data-testid="default-slot">Form</span>',
      },
      stubs: {
        GlLoadingIcon,
      },
    });
  }

  describe('Error alert', () => {
    it('shows the alert when an error are passed in', () => {
      const error = 'Bad things happened';

      wrapper = createComponent({ error });

      expect(findAlert().text()).toBe(error);
      expect(findDefaultSlot().exists()).toBe(true);
    });
  });

  describe('Loading', () => {
    it('shows the loading icon when loading is passed in', () => {
      wrapper = createComponent({ loading: true });

      expect(findLoadingIcon().exists()).toBe(true);
      expect(findDefaultSlot().exists()).toBe(false);
    });
  });

  describe('Default slot', () => {
    it('shows by default', () => {
      wrapper = createComponent();

      expect(findDefaultSlot().exists()).toBe(true);
    });
  });
});
