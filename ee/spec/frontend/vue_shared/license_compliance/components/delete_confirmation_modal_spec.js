import { GlModal, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import Component from 'ee/vue_shared/license_compliance/components/delete_confirmation_modal.vue';
import { allowedLicense } from '../mock_data';

Vue.use(Vuex);

describe('DeleteConfirmationModal', () => {
  let store;
  let wrapper;

  const mockEvent = { preventDefault: jest.fn() };
  const actions = {
    resetLicenseInModal: jest.fn(),
    deleteLicense: jest.fn(),
  };

  const createStore = (initialState = {}) => {
    return new Vuex.Store({
      modules: {
        licenseManagement: {
          namespaced: true,
          state: {
            currentLicenseInModal: allowedLicense,
            ...initialState,
          },
          actions,
        },
      },
    });
  };

  const createComponent = (initialState) => {
    store = createStore(initialState);

    wrapper = shallowMount(Component, {
      store,
      stubs: {
        GlModal,
        GlSprintf,
      },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);

  beforeEach(() => {
    createComponent();
  });

  describe('modal', () => {
    it('should be loaded', () => {
      expect(findModal().exists()).toBe(true);
    });

    it('should have Primary and Cancel actions', () => {
      expect(findModal().props()).toMatchObject({
        actionPrimary: {
          text: 'Remove license',
        },
        actionCancel: {
          text: 'Cancel',
        },
      });
    });

    it('should have the confirmation text', () => {
      expect(findModal().html()).toContain(
        `You are about to remove the license, <strong>${allowedLicense.name}</strong>, from this project.`,
      );
    });

    it('should escape the confirmation text', () => {
      const name = '<a href="#">BAD</a>';
      const nameEscaped = '&lt;a href="#"&gt;BAD&lt;/a&gt;';

      const currentLicenseInModal = {
        ...allowedLicense,
        name,
      };

      createComponent({
        currentLicenseInModal,
      });

      expect(findModal().html()).toContain(
        `You are about to remove the license, <strong>${nameEscaped}</strong>, from this project`,
      );
    });
  });

  describe('interaction', () => {
    it('triggering resetLicenseInModal on cancel', async () => {
      findModal().vm.$emit('cancel', mockEvent);
      await nextTick();
      expect(actions.resetLicenseInModal).toHaveBeenCalled();
    });

    it('triggering deleteLicense on cancel', async () => {
      findModal().vm.$emit('primary', mockEvent);
      await nextTick();
      expect(actions.deleteLicense).toHaveBeenCalled();
    });
  });
});
