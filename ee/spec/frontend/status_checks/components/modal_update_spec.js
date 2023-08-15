import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import ModalUpdate from 'ee/status_checks/components/modal_update.vue';
import SharedModal from 'ee/status_checks/components/shared_modal.vue';
import { TEST_PROTECTED_BRANCHES } from 'ee_jest/vue_shared/components/branches_selector/mock_data';

Vue.use(Vuex);

const projectId = '1';
const statusChecksPath = '/api/v4/projects/1/external_approval_rules';
const modalId = 'status-checks-update-modal';
const title = 'Update status check';
const statusCheck = {
  externalUrl: 'https://foo.com',
  id: 1,
  name: 'Foo',
  protectedBranches: TEST_PROTECTED_BRANCHES,
};

describe('Modal update', () => {
  let wrapper;
  let store;
  const actions = {
    putStatusCheck: jest.fn(),
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

    wrapper = shallowMount(ModalUpdate, {
      propsData: {
        statusCheck,
      },
      store,
    });
  };

  beforeEach(() => {
    createWrapper();
  });

  const findModal = () => wrapper.findComponent(SharedModal);

  describe('Modal', () => {
    it('sets the modals props', () => {
      expect(findModal().props()).toStrictEqual({
        action: expect.any(Function),
        modalId,
        title,
        statusCheck,
      });
    });
  });
});
