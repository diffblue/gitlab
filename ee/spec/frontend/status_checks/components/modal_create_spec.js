import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import ModalCreate from 'ee/status_checks/components/modal_create.vue';
import SharedModal from 'ee/status_checks/components/shared_modal.vue';

Vue.use(Vuex);

const projectId = '1';
const statusChecksPath = '/api/v4/projects/1/external_approval_rules';
const modalId = 'status-checks-create-modal';
const title = 'Add status check';

describe('Modal create', () => {
  let wrapper;
  let store;
  const actions = {
    postStatusCheck: jest.fn(),
  };

  const createWrapper = () => {
    store = new Vuex.Store({
      actions,
      state: {
        isLoading: false,
        settings: { projectId, statusChecksPath },
        statusChecks: [],
      },
    });

    wrapper = shallowMount(ModalCreate, {
      store,
      stubs: {
        GlButton,
      },
    });

    wrapper.vm.$refs.modal.show = jest.fn();
  };

  beforeEach(() => {
    createWrapper();
  });

  const findAddBtn = () => wrapper.findComponent(GlButton);
  const findModal = () => wrapper.findComponent(SharedModal);

  describe('Add button', () => {
    it('renders', () => {
      expect(findAddBtn().text()).toBe('Add status check');
    });

    it('opens the modal', () => {
      findAddBtn().trigger('click');
      expect(wrapper.vm.$refs.modal.show).toHaveBeenCalled();
    });
  });

  describe('Modal', () => {
    it('sets the modals props', () => {
      expect(findModal().props()).toStrictEqual({
        action: expect.any(Function),
        modalId,
        title,
        statusCheck: undefined,
      });
    });
  });
});
