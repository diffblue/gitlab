import { GlToggle, GlFormTextarea, GlForm, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import MaintenanceModeSettingsApp from 'ee/maintenance_mode_settings/components/app.vue';
import { MOCK_BASIC_SETTINGS_DATA } from '../mock_data';

Vue.use(Vuex);

describe('MaintenanceModeSettingsApp', () => {
  let wrapper;

  const actionSpies = {
    updateMaintenanceModeSettings: jest.fn(),
    setMaintenanceEnabled: jest.fn(),
    setBannerMessage: jest.fn(),
  };

  const createComponent = (initialState) => {
    const store = new Vuex.Store({
      state: {
        ...MOCK_BASIC_SETTINGS_DATA,
        ...initialState,
      },
      actions: actionSpies,
    });

    wrapper = shallowMount(MaintenanceModeSettingsApp, {
      store,
    });
  };

  const findMaintenanceModeSettingsForm = () => wrapper.findComponent(GlForm);
  const findGlLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findGlToggle = () => wrapper.findComponent(GlToggle);
  const findGlFormTextarea = () => wrapper.findComponent(GlFormTextarea);
  const findSubmitButton = () => findMaintenanceModeSettingsForm().find('[type="submit"]');

  describe('template', () => {
    describe('when loading is true', () => {
      beforeEach(() => {
        createComponent({ loading: true });
      });

      it('renders GlLoadingIcon', () => {
        expect(findGlLoadingIcon().exists()).toBe(true);
      });

      it('does not render the MaintenanceModeSettingsForm', () => {
        expect(findMaintenanceModeSettingsForm().exists()).toBe(false);
      });
    });

    describe('when loading is false', () => {
      beforeEach(() => {
        createComponent();
      });

      it('does not render GlLoadingIcon', () => {
        expect(findGlLoadingIcon().exists()).toBe(false);
      });

      it('renders the MaintenanceModeSettingsForm', () => {
        expect(findMaintenanceModeSettingsForm().exists()).toBe(true);
      });

      it('renders the submit button', () => {
        expect(findSubmitButton().exists()).toBe(true);
      });
    });
  });

  describe('GlToggle', () => {
    it('has label', () => {
      createComponent();

      expect(findGlToggle().props('label')).toBe(MaintenanceModeSettingsApp.i18n.toggleLabel);
    });

    describe('onChange', () => {
      beforeEach(() => {
        createComponent();
        findGlToggle().vm.$emit('change', false);
      });

      it('calls setMaintenanceEnabled with the new boolean', () => {
        expect(actionSpies.setMaintenanceEnabled).toHaveBeenCalledWith(expect.any(Object), {
          maintenanceEnabled: false,
        });
      });
    });
  });

  describe('GlFormTextarea', () => {
    describe('onInput', () => {
      beforeEach(() => {
        createComponent();
        findGlFormTextarea().vm.$emit('input', 'Hello World');
      });

      it('calls setBannerMessage with the new string', () => {
        expect(actionSpies.setBannerMessage).toHaveBeenCalledWith(expect.any(Object), {
          bannerMessage: 'Hello World',
        });
      });
    });
  });

  describe('MaintenanceModeSettingsForm', () => {
    describe('onSubmit', () => {
      beforeEach(() => {
        createComponent();
        findMaintenanceModeSettingsForm().vm.$emit('submit', { preventDefault: () => {} });
      });

      it('calls updateMaintenanceModeSettings', () => {
        expect(actionSpies.updateMaintenanceModeSettings).toHaveBeenCalledTimes(1);
      });
    });
  });
});
