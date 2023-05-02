import { GlButton, GlForm, GlLoadingIcon, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';

import ApprovalSettings from 'ee/approvals/components/approval_settings.vue';
import {
  PROJECT_APPROVAL_SETTINGS_LABELS_I18N,
  APPROVAL_SETTINGS_I18N,
} from 'ee/approvals/constants';
import { mergeRequestApprovalSettingsMappers } from 'ee/approvals/mappers';
import createStore from 'ee/approvals/stores';
import approvalSettingsModule from 'ee/approvals/stores/modules/approval_settings/';
import projectSettingsModule from 'ee/approvals/stores/modules/project_settings/';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { sprintf } from '~/locale';
import { createGroupApprovalsPayload, createGroupApprovalsState } from '../mocks';

Vue.use(Vuex);

describe('ApprovalSettings', () => {
  let wrapper;
  let store;
  let actions;

  const groupApprovalsPayload = createGroupApprovalsPayload();
  const approvalSettingsPath = 'groups/22/merge_request_approval_settings';
  const groupName = 'GitLab Org';

  const setupStore = (data = {}, initialData) => {
    const module = approvalSettingsModule(mergeRequestApprovalSettingsMappers);

    module.state.settings = data;
    module.state.initialSettings = initialData || data;
    actions = module.actions;
    jest.spyOn(actions, 'fetchSettings').mockImplementation();
    jest.spyOn(actions, 'updateSettings').mockImplementation();
    jest.spyOn(actions, 'dismissErrorMessage').mockImplementation();

    store = createStore({ approvalSettings: module, approvals: projectSettingsModule() });
    store.state.settings.groupName = groupName;
  };

  const showToast = jest.fn();
  const mocks = {
    $toast: {
      show: showToast,
    },
  };

  const createWrapper = (props = {}) => {
    wrapper = extendedWrapper(
      shallowMount(ApprovalSettings, {
        store,
        propsData: {
          approvalSettingsPath,
          settingsLabels: PROJECT_APPROVAL_SETTINGS_LABELS_I18N,
          ...props,
        },
        stubs: { GlButton },
        mocks,
      }),
    );
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findErrorAlert = () => wrapper.findByTestId('error-alert');
  const findSuccessAlert = () => wrapper.findByTestId('success-alert');
  const findForm = () => wrapper.findComponent(GlForm);
  const findSaveButton = () => wrapper.findComponent(GlButton);
  const findLink = () => wrapper.findComponent(GlLink);
  const findSelectiveCodeOwnersRadio = () => wrapper.findByTestId('selective-code-owner-removals');

  afterEach(() => {
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
    const { settings } = createGroupApprovalsState();

    beforeEach(() => {
      setupStore(settings);
    });

    it('renders the form once successfully loaded', async () => {
      createWrapper();
      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
      expect(findErrorAlert().exists()).toBe(false);
      expect(findSuccessAlert().exists()).toBe(false);
      expect(findForm().exists()).toBe(true);
    });

    it('renders the button as not loading when loaded', async () => {
      createWrapper();
      await waitForPromises();

      expect(findSaveButton().props('loading')).toBe(false);
    });

    it('renders the button as loading when updating', async () => {
      createWrapper();
      await waitForPromises();
      await store.commit('REQUEST_UPDATE_SETTINGS');

      expect(findSaveButton().props('loading')).toBe(true);
    });

    it('renders the button as disabled when setting are unchanged', async () => {
      createWrapper();
      await waitForPromises();

      expect(findSaveButton().attributes('disabled')).toBeDefined();
    });

    it('renders the button as enabled when a setting was changed', async () => {
      const changedSettings = {
        ...settings,
        preventAuthorApproval: {
          ...settings.preventAuthorApproval,
          value: true,
        },
      };

      setupStore(changedSettings, settings);

      createWrapper();
      await waitForPromises();

      expect(findSaveButton().attributes('disabled')).toBeUndefined();
    });

    it('renders the approval settings heading', async () => {
      createWrapper();
      await waitForPromises();

      expect(findForm().text()).toContain('Approval settings');
      expect(findForm().text()).toContain(
        'Define how approval rules are applied to merge requests.',
      );
    });

    it('renders the help link', async () => {
      createWrapper();
      await waitForPromises();

      expect(findLink().text()).toBe('Learn more.');
      expect(findLink().attributes('href')).toBe(
        '/help/user/project/merge_requests/approvals/settings',
      );
    });

    describe('selective code owner removals', () => {
      beforeEach(() => {
        jest.spyOn(store, 'dispatch').mockImplementation();
      });

      it('renders for project with remove approvals on push enabled', () => {
        createWrapper({ approvalSettingsPath: '/api/v4/projects/19/' });

        expect(findSelectiveCodeOwnersRadio().exists()).toBe(true);
      });

      it('does not render for group', () => {
        createWrapper({ approvalSettingsPath: '/api/v4/groups/19/' });

        expect(findSelectiveCodeOwnersRadio().exists()).toBe(false);
      });
    });

    describe.each`
      testid                             | action                            | setting                        | labelKey
      ${'prevent-author-approval'}       | ${'setPreventAuthorApproval'}     | ${'preventAuthorApproval'}     | ${'authorApprovalLabel'}
      ${'prevent-committers-approval'}   | ${'setPreventCommittersApproval'} | ${'preventCommittersApproval'} | ${'preventCommittersApprovalLabel'}
      ${'prevent-mr-approval-rule-edit'} | ${'setPreventMrApprovalRuleEdit'} | ${'preventMrApprovalRuleEdit'} | ${'preventMrApprovalRuleEditLabel'}
      ${'require-user-password'}         | ${'setRequireUserPassword'}       | ${'requireUserPassword'}       | ${'requireUserPasswordLabel'}
    `('with the $testid checkbox', ({ testid, action, setting, labelKey }) => {
      let checkbox = null;

      beforeEach(async () => {
        jest.spyOn(store, 'dispatch').mockImplementation();
        createWrapper({ approvalSettingsPath: '/api/v4/projects/19/' });
        await waitForPromises();
        checkbox = wrapper.findByTestId(testid);
      });

      afterEach(() => {
        checkbox = null;
      });

      it('renders checkbox', () => {
        expect(checkbox.exists()).toBe(true);
      });

      it('checkbox has the label prop', () => {
        expect(checkbox.props('label')).toBe(PROJECT_APPROVAL_SETTINGS_LABELS_I18N[labelKey]);
      });

      it('sets the checkbox locked prop', () => {
        expect(checkbox.props('locked')).toBe(settings[setting].locked);
      });

      it('sets the checkbox lockedText prop', () => {
        const { inheritedFrom, locked } = settings[setting];

        let expectedText = null;

        if (locked && inheritedFrom === 'group') {
          expectedText = sprintf(APPROVAL_SETTINGS_I18N.lockedByGroupOwner, { groupName });
        } else if (locked && inheritedFrom === 'instance') {
          expectedText = APPROVAL_SETTINGS_I18N.lockedByAdmin;
        }

        expect(checkbox.props('lockedText')).toBe(expectedText);
      });

      it(`triggers the action ${action} when the checkbox value is changed`, async () => {
        await checkbox.vm.$emit('input', true);
        await waitForPromises();

        expect(store.dispatch).toHaveBeenLastCalledWith(action, true);
      });
    });

    describe.each`
      testid                             | labelKey
      ${'keep-approvals-on-push'}        | ${'keepApprovalsLabel'}
      ${'remove-approvals-on-push'}      | ${'removeApprovalsOnPushLabel'}
      ${'selective-code-owner-removals'} | ${'selectiveCodeOwnerRemovalsLabel'}
    `('with the $testid radio', ({ testid, labelKey }) => {
      let radio = null;

      beforeEach(async () => {
        jest.spyOn(store, 'dispatch').mockImplementation();
        createWrapper({ approvalSettingsPath: '/api/v4/projects/19/' });
        await waitForPromises();
        radio = wrapper.findByTestId(testid);
      });

      afterEach(() => {
        radio = null;
      });

      it('renders radio', () => {
        expect(radio.exists()).toBe(true);
      });

      it('radio has the label prop', () => {
        expect(radio.props('label')).toBe(PROJECT_APPROVAL_SETTINGS_LABELS_I18N[labelKey]);
      });

      it('sets the radio locked prop', () => {
        expect(radio.props('locked')).toBe(settings.removeApprovalsOnPush.locked);
      });

      it('sets the radio lockedText prop', () => {
        const { inheritedFrom, locked } = settings.removeApprovalsOnPush;

        let expectedText = null;

        if (locked && inheritedFrom === 'group') {
          expectedText = sprintf(APPROVAL_SETTINGS_I18N.lockedByGroupOwner, { groupName });
        } else if (locked && inheritedFrom === 'instance') {
          expectedText = APPROVAL_SETTINGS_I18N.lockedByAdmin;
        }

        expect(radio.props('lockedText')).toBe(expectedText);
      });
    });

    describe.each`
      value
      ${'keep-approvals'}
      ${'remove-approvals-on-push'}
      ${'selective-code-owner-removals'}
    `('with the $testid radio', ({ value }) => {
      let radios = null;

      beforeEach(async () => {
        jest.spyOn(store, 'dispatch').mockImplementation();
        createWrapper({ approvalSettingsPath: '/api/v4/projects/19/' });
        await waitForPromises();
        radios = wrapper.findByTestId('when-commit-is-added-radios');
      });

      afterEach(() => {
        radios = null;
      });

      it(`triggers the relevant actions with the relevant values when the value is changed`, () => {
        radios.vm.$emit('input', value);

        expect(store.dispatch).toHaveBeenCalledWith(
          'setRemoveApprovalsOnPush',
          value === 'remove-approvals-on-push',
        );
        expect(store.dispatch).toHaveBeenCalledWith(
          'setSelectiveCodeOwnerRemovals',
          value === 'selective-code-owner-removals',
        );
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

        it('does not show a toast message', () => {
          expect(showToast).not.toHaveBeenCalled();
        });
      });

      describe('if the form updates', () => {
        beforeEach(async () => {
          createWrapper();

          await waitForPromises();
          await findForm().vm.$emit('submit', { preventDefault: () => {} });
          await store.commit('UPDATE_SETTINGS_SUCCESS', groupApprovalsPayload);
        });

        it('update the settings', () => {
          expect(actions.updateSettings).toHaveBeenCalledWith(
            expect.any(Object),
            approvalSettingsPath,
          );
        });

        it('shows the success toast', () => {
          expect(showToast).toHaveBeenCalledWith(APPROVAL_SETTINGS_I18N.savingSuccessMessage);
        });
      });
    });

    describe('locked settings', () => {
      beforeEach(() => {
        setupStore(createGroupApprovalsState(false).settings);
      });

      it.each`
        property                          | value    | locked   | testid
        ${'canPreventAuthorApproval'}     | ${true}  | ${false} | ${'prevent-author-approval'}
        ${'canPreventMrApprovalRuleEdit'} | ${true}  | ${false} | ${'prevent-mr-approval-rule-edit'}
        ${'canPreventCommittersApproval'} | ${true}  | ${false} | ${'prevent-committers-approval'}
        ${'canPreventAuthorApproval'}     | ${false} | ${true}  | ${'prevent-author-approval'}
        ${'canPreventMrApprovalRuleEdit'} | ${false} | ${true}  | ${'prevent-mr-approval-rule-edit'}
        ${'canPreventCommittersApproval'} | ${false} | ${true}  | ${'prevent-committers-approval'}
      `(
        `when $property is $value, then $testid has "locked" set to $locked`,
        ({ property, value, locked, testid }) => {
          createWrapper({ [property]: value });

          expect(wrapper.findByTestId(testid).props('locked')).toBe(locked);
        },
      );
    });
  });
});
