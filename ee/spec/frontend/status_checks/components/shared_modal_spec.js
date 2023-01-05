import { GlButton, GlModal } from '@gitlab/ui';
import Vue from 'vue';
import Vuex from 'vuex';
import Form from 'ee/status_checks/components/form.vue';
import SharedModal from 'ee/status_checks/components/shared_modal.vue';
import { EMPTY_STATUS_CHECK } from 'ee/status_checks/constants';
import { stubComponent } from 'helpers/stub_component';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { TEST_PROTECTED_BRANCHES } from 'ee_jest/vue_shared/components/branches_selector/mock_data';

Vue.use(Vuex);

const projectId = '1';
const statusChecksPath = '/api/v4/projects/1/external_approval_rules';
const modalId = 'modal-id';
const title = 'Modal title';
const statusCheck = {
  externalUrl: 'https://foo.com',
  id: 1,
  name: 'Foo',
  protectedBranches: TEST_PROTECTED_BRANCHES,
};
const formData = {
  branches: statusCheck.protectedBranches,
  name: statusCheck.name,
  url: statusCheck.externalUrl,
};

describe('Shared modal', () => {
  let wrapper;
  let store;
  const glModalDirective = jest.fn();
  const action = jest.fn();

  const createWrapper = (props = {}) => {
    store = new Vuex.Store({
      state: {
        isLoading: false,
        settings: { projectId, statusChecksPath },
        statusChecks: [],
      },
    });

    wrapper = shallowMountExtended(SharedModal, {
      directives: {
        glModal: {
          bind(el, { modifiers }) {
            glModalDirective(modifiers);
          },
        },
      },
      propsData: {
        action,
        modalId,
        title,
        ...props,
      },
      store,
      stubs: {
        GlButton: stubComponent(GlButton, {
          props: ['v-gl-modal', 'loading'],
        }),
      },
    });

    wrapper.vm.$refs.modal.hide = jest.fn();
    wrapper.vm.$refs.form.submit = jest.fn();
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findForm = () => wrapper.findComponent(Form);

  describe('Modal', () => {
    describe('defaults', () => {
      beforeEach(() => {
        createWrapper();
      });

      it('sets the modals props', () => {
        expect(findModal().props()).toMatchObject({
          actionPrimary: { text: title, attributes: { variant: 'confirm', loading: false } },
          actionCancel: { text: 'Cancel' },
          modalId,
          size: 'sm',
          title,
        });
      });
    });

    describe.each`
      given          | expected
      ${undefined}   | ${EMPTY_STATUS_CHECK}
      ${statusCheck} | ${statusCheck}
    `('when the $given status check is passed', ({ given, expected }) => {
      beforeEach(() => {
        createWrapper({ statusCheck: given });
      });

      it('shows the form with the correct props', () => {
        expect(findForm().props()).toMatchObject({
          projectId,
          serverValidationErrors: [],
          statusCheck: expected,
        });
      });
    });
  });

  describe('Submission', () => {
    describe.each`
      given          | expected
      ${undefined}   | ${EMPTY_STATUS_CHECK}
      ${statusCheck} | ${statusCheck}
    `('when the $given status check is passed', ({ given, expected }) => {
      beforeEach(() => {
        createWrapper({ statusCheck: given });
      });

      it('submits the values and hides the modal', async () => {
        await findModal().vm.$emit('ok', { preventDefault: () => null });
        await findForm().vm.$emit('submit', formData);
        await waitForPromises();

        expect(wrapper.vm.$refs.form.submit).toHaveBeenCalled();
        expect(action).toHaveBeenCalledWith({
          externalUrl: formData.url,
          id: expected?.id,
          name: formData.name,
          protectedBranchIds: formData.branches.map(({ id }) => id),
        });

        expect(wrapper.vm.$refs.modal.hide).toHaveBeenCalled();
      });

      it('submits the values, the API fails and does not hide the modal', async () => {
        const message = ['Name has already been taken'];

        action.mockRejectedValueOnce({
          response: { data: { message } },
        });

        await findModal().vm.$emit('ok', { preventDefault: () => null });
        await findForm().vm.$emit('submit', formData);
        await waitForPromises();

        expect(wrapper.vm.$refs.form.submit).toHaveBeenCalled();

        expect(action).toHaveBeenCalledWith({
          externalUrl: formData.url,
          id: expected?.id,
          name: formData.name,
          protectedBranchIds: formData.branches.map(({ id }) => id),
        });

        expect(wrapper.vm.$refs.modal.hide).not.toHaveBeenCalled();

        expect(findForm().props()).toMatchObject({
          projectId,
          serverValidationErrors: message,
          statusCheck: expected,
        });
      });
    });
  });
});
