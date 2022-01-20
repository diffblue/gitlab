import { GlToggle } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import RegistrationTrialToggle from 'ee/registrations/components/registration_trial_toggle.vue';

describe('Registration Trial Toggle', () => {
  let wrapper;

  const createComponent = (propsData) => {
    wrapper = shallowMount(RegistrationTrialToggle, {
      propsData,
    });
  };

  beforeEach(() => {
    createComponent({ active: false });
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('Default state', () => {
    it('renders component properly', () => {
      expect(wrapper.findComponent(RegistrationTrialToggle).exists()).toBe(true);
    });

    it('shows the toggle component', () => {
      expect(wrapper.findComponent(GlToggle).props('label')).toBe(
        RegistrationTrialToggle.i18n.toggleLabel,
      );
    });

    it('sets the default value to be false', () => {
      expect(wrapper.vm.trial).toBe(false);
    });
  });

  describe('Emits events', () => {
    it('emits initial event', () => {
      expect(wrapper.emitted().changed).toEqual([[{ trial: false }]]);
    });

    it('emits another event', () => {
      wrapper.findComponent(GlToggle).vm.$emit('change', true);

      expect(wrapper.vm.trial).toBe(true);
      expect(wrapper.emitted().changed).toEqual([[{ trial: false }], [{ trial: true }]]);
    });
  });
});
