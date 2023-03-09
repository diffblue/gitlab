import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import ApprovalSettings from 'ee/approvals/components/approval_settings.vue';
import ProjectApprovalSettings from 'ee/approvals/components/project_settings/project_approval_settings.vue';
import { PROJECT_APPROVAL_SETTINGS_LABELS_I18N } from 'ee/approvals/constants';
import { mergeRequestApprovalSettingsMappers } from 'ee/approvals/mappers';
import createStore from 'ee/approvals/stores';
import approvalSettingsModule from 'ee/approvals/stores/modules/approval_settings';

Vue.use(Vuex);

describe('ProjectApprovalSettings', () => {
  let wrapper;
  let store;

  const findApprovalSettings = () => wrapper.findComponent(ApprovalSettings);

  const setupStore = (data = {}) => {
    store = createStore({
      approvalSettings: approvalSettingsModule(mergeRequestApprovalSettingsMappers),
    });

    store.state.settings = data;
  };

  const createWrapper = () => {
    wrapper = shallowMount(ProjectApprovalSettings, { store });
  };

  afterEach(() => {
    store = null;
  });

  it('configures the app with the store values', () => {
    setupStore({
      approvalsPath: 'foo',
      canEdit: true,
      canModifyAuthorSettings: false,
      canModifyCommiterSettings: true,
    });
    createWrapper();

    expect(findApprovalSettings().props()).toMatchObject({
      approvalSettingsPath: 'foo',
      canPreventMrApprovalRuleEdit: true,
      canPreventAuthorApproval: false,
      canPreventCommittersApproval: true,
      settingsLabels: PROJECT_APPROVAL_SETTINGS_LABELS_I18N,
    });
  });
});
