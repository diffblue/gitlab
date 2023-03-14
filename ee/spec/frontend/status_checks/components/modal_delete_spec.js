import { GlModal, GlSprintf } from '@gitlab/ui';
import Vue from 'vue';
import Vuex from 'vuex';
import ModalDelete from 'ee/status_checks/components/modal_delete.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';

jest.mock('~/alert');

Vue.use(Vuex);

const projectId = '1';
const statusChecksPath = '/api/v4/projects/1/external_approval_rules';
const statusCheck = {
  externalUrl: 'https://foo.com',
  id: 1,
  name: 'Foo',
  protectedBranches: [],
};
const modalId = 'status-checks-delete-modal';

describe('Modal delete', () => {
  let wrapper;
  let store;
  const glModalDirective = jest.fn();
  const actions = {
    deleteStatusCheck: jest.fn(),
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

    wrapper = shallowMountExtended(ModalDelete, {
      directives: {
        glModal: {
          bind(el, { modifiers }) {
            glModalDirective(modifiers);
          },
        },
      },
      propsData: {
        statusCheck,
      },
      store,
      stubs: { GlSprintf },
    });

    wrapper.vm.$refs.modal.hide = jest.fn();
  };

  beforeEach(() => {
    createWrapper();
  });

  const findModal = () => wrapper.findComponent(GlModal);

  const clickModalOk = async () => {
    await findModal().vm.$emit('ok', { preventDefault: () => null });

    return waitForPromises();
  };

  describe('Modal', () => {
    it('sets the modals props', () => {
      expect(findModal().props()).toMatchObject({
        actionPrimary: {
          text: 'Remove status check',
          attributes: { variant: 'danger', loading: false },
        },
        actionCancel: { text: 'Cancel' },
        modalId,
        size: 'sm',
        title: 'Remove status check?',
      });
    });

    it('the modal text matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('Submission', () => {
    it('submits and hides the modal', async () => {
      await clickModalOk();

      expect(actions.deleteStatusCheck).toHaveBeenCalledWith(expect.any(Object), statusCheck.id);

      expect(wrapper.vm.$refs.modal.hide).toHaveBeenCalled();
    });

    it('submits, hides the modal and shows the error', async () => {
      const error = new Error('Something went wrong');

      actions.deleteStatusCheck.mockRejectedValueOnce(error);

      await clickModalOk();

      expect(actions.deleteStatusCheck).toHaveBeenCalledWith(expect.any(Object), statusCheck.id);

      expect(wrapper.vm.$refs.modal.hide).toHaveBeenCalled();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'An error occurred deleting the Foo status check.',
        captureError: true,
        error,
      });
    });
  });
});
