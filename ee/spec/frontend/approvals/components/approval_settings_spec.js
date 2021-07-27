import { GlButton, GlForm, GlLoadingIcon } from '@gitlab/ui';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';

import ApprovalSettings from 'ee/approvals/components/approval_settings.vue';
import { APPROVAL_SETTINGS_I18N } from 'ee/approvals/constants';
import { groupApprovalsMappers } from 'ee/approvals/mappers';
import createStore from 'ee/approvals/stores';
import approvalSettingsModule from 'ee/approvals/stores/modules/approval_settings/';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('ApprovalSettings', () => {
  let wrapper;
  let store;
  let actions;

  const approvalSettingsPath = 'groups/22/merge_request_approval_settings';

  const setupStore = (data = {}) => {
    const module = approvalSettingsModule(groupApprovalsMappers);

    module.state.settings = data;
    actions = module.actions;
    jest.spyOn(actions, 'fetchSettings').mockImplementation();
    jest.spyOn(actions, 'updateSettings').mockImplementation();
    jest.spyOn(actions, 'dismissErrorMessage').mockImplementation();
    jest.spyOn(actions, 'dismissSuccessMessage').mockImplementation();

    store = createStore({ approvalSettings: module });
  };

  const createWrapper = () => {
    wrapper = extendedWrapper(
      shallowMount(ApprovalSettings, {
        localVue,
        store,
        propsData: { approvalSettingsPath },
      }),
    );
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findErrorAlert = () => wrapper.findByTestId('error-alert');
  const findSuccessAlert = () => wrapper.findByTestId('success-alert');
  const findForm = () => wrapper.findComponent(GlForm);
  const findSaveButton = () => wrapper.findComponent(GlButton);

  afterEach(() => {
    wrapper.destroy();
    store = null;
  });

  it('fetches settings from API', () => {
    setupStore();
    createWrapper();

    expect(actions.fetchSettings).toHaveBeenCalledWith(expect.any(Object), approvalSettingsPath);
  });

  describe('before loaded', () => {
    beforeEach(() => {
      setupStore();
    });

    it('renders the loading icon and not the form if the settings are not there yet', () => {
      createWrapper();

      expect(findLoadingIcon().exists()).toBe(true);
      expect(findErrorAlert().exists()).toBe(false);
      expect(findSuccessAlert().exists()).toBe(false);
      expect(findForm().exists()).toBe(false);
    });

    it('renders the alert and not the form if an initial error occurs', async () => {
      createWrapper();

      await store.commit('RECEIVE_SETTINGS_ERROR');
      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
      expect(findErrorAlert().text()).toBe(APPROVAL_SETTINGS_I18N.loadingErrorMessage);
      expect(findErrorAlert().classes('gl-mb-6')).toBe(false);
      expect(findForm().exists()).toBe(false);
    });
  });

  describe('with settings', () => {
    beforeEach(() => {
      setupStore({
        allow_author_approval: false,
        allow_committer_approval: false,
        allow_overrides_to_approver_list_per_merge_request: false,
        require_password_to_approve: false,
        retain_approvals_on_push: false,
      });
    });

    it('renders the form once successfully loaded', async () => {
      createWrapper();
      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
      expect(findErrorAlert().exists()).toBe(false);
      expect(findSuccessAlert().exists()).toBe(false);
      expect(findForm().exists()).toBe(true);
    });

    it('renders enabled button when not loading', async () => {
      createWrapper();
      await waitForPromises();

      expect(findSaveButton().props('loading')).toBe(false);
    });

    it('renders loading button when loading', async () => {
      createWrapper();
      await waitForPromises();
      await store.commit('REQUEST_UPDATE_SETTINGS');

      expect(findSaveButton().props('loading')).toBe(true);
    });

    describe.each`
      testid                             | action                            | setting                        | labelKey                            | anchor
      ${'prevent-author-approval'}       | ${'setPreventAuthorApproval'}     | ${'preventAuthorApproval'}     | ${'authorApprovalLabel'}            | ${'allowing-merge-request-authors-to-approve-their-own-merge-requests'}
      ${'prevent-committers-approval'}   | ${'setPreventCommittersApproval'} | ${'preventCommittersApproval'} | ${'preventCommittersApprovalLabel'} | ${'prevent-approval-of-merge-requests-by-their-committers'}
      ${'prevent-mr-approval-rule-edit'} | ${'setPreventMrApprovalRuleEdit'} | ${'preventMrApprovalRuleEdit'} | ${'preventMrApprovalRuleEditLabel'} | ${'editing--overriding-approval-rules-per-merge-request'}
      ${'require-user-password'}         | ${'setRequireUserPassword'}       | ${'requireUserPassword'}       | ${'requireUserPasswordLabel'}       | ${'require-authentication-when-approving-a-merge-request'}
      ${'remove-approvals-on-push'}      | ${'setRemoveApprovalsOnPush'}     | ${'removeApprovalsOnPush'}     | ${'removeApprovalsOnPushLabel'}     | ${'resetting-approvals-on-push'}
    `('with the $testid checkbox', ({ testid, action, setting, labelKey, anchor }) => {
      let checkbox = null;

      beforeEach(async () => {
        jest.spyOn(store, 'dispatch').mockImplementation();
        createWrapper();
        await waitForPromises();
        checkbox = wrapper.findByTestId(testid);
      });

      afterEach(() => {
        checkbox = null;
      });

      it('renders', () => {
        expect(checkbox.exists()).toBe(true);
      });

      it('has the anchor and label props', () => {
        expect(checkbox.props()).toMatchObject({
          anchor,
          label: APPROVAL_SETTINGS_I18N[labelKey],
        });
      });

      it(`triggers the action ${action} when the value is changed`, async () => {
        await checkbox.vm.$emit('input', true);
        await waitForPromises();

        expect(store.dispatch).toHaveBeenLastCalledWith(action, { [setting]: true });
      });
    });

    describe('form submission', () => {
      describe('if an error occurs while updating', () => {
        beforeEach(async () => {
          createWrapper();

          await waitForPromises();
          await store.commit('UPDATE_SETTINGS_ERROR');
        });

        it('renders the alert', () => {
          expect(findErrorAlert().text()).toBe(APPROVAL_SETTINGS_I18N.savingErrorMessage);
          expect(findErrorAlert().classes('gl-mb-6')).toBe(true);
          expect(findSuccessAlert().exists()).toBe(false);
        });

        it('dismisses the alert', async () => {
          await findErrorAlert().vm.$emit('dismiss');

          expect(actions.dismissErrorMessage).toHaveBeenCalled();
        });
      });

      describe('if the form updates', () => {
        beforeEach(async () => {
          createWrapper();

          await waitForPromises();
          await findForm().vm.$emit('submit', { preventDefault: () => {} });
          await store.commit('UPDATE_SETTINGS_SUCCESS', {});
        });

        it('update the settings', () => {
          expect(actions.updateSettings).toHaveBeenCalledWith(
            expect.any(Object),
            approvalSettingsPath,
          );
        });

        it('renders the alert', () => {
          expect(findErrorAlert().exists()).toBe(false);
          expect(findSuccessAlert().text()).toBe(APPROVAL_SETTINGS_I18N.savingSuccessMessage);
        });

        it('dismisses the alert', async () => {
          await findSuccessAlert().vm.$emit('dismiss');

          expect(actions.dismissSuccessMessage).toHaveBeenCalled();
        });
      });
    });
  });
});
