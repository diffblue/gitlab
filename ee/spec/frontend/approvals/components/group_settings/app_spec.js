import { GlSprintf, GlLink } from '@gitlab/ui';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import Vuex from 'vuex';

import ApprovalSettings from 'ee/approvals/components/approval_settings.vue';
import GroupSettingsApp from 'ee/approvals/components/group_settings/app.vue';
import { groupApprovalsMappers } from 'ee/approvals/mappers';
import { createStoreOptions } from 'ee/approvals/stores';
import approvalSettingsModule from 'ee/approvals/stores/modules/approval_settings';
import SettingsBlock from '~/vue_shared/components/settings/settings_block.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('EE Approvals Group Settings App', () => {
  let wrapper;
  let store;
  let axiosMock;

  const defaultExpanded = true;
  const approvalSettingsPath = 'groups/22/merge_request_approval_settings';

  const createWrapper = () => {
    wrapper = shallowMount(GroupSettingsApp, {
      localVue,
      store: new Vuex.Store(store),
      propsData: {
        defaultExpanded,
        approvalSettingsPath,
      },
      stubs: {
        ApprovalSettings,
        GlLink,
        GlSprintf,
        SettingsBlock,
      },
    });
  };

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);
    axiosMock.onGet('*');

    store = createStoreOptions({ approvalSettings: approvalSettingsModule(groupApprovalsMappers) });
  });

  afterEach(() => {
    wrapper.destroy();
    store = null;
  });

  const findSettingsBlock = () => wrapper.find(SettingsBlock);
  const findLink = () => wrapper.find(GlLink);
  const findApprovalSettings = () => wrapper.find(ApprovalSettings);

  it('renders a settings block', () => {
    createWrapper();

    expect(findSettingsBlock().exists()).toBe(true);
    expect(findSettingsBlock().props('defaultExpanded')).toBe(true);
  });

  it('has the correct link', () => {
    createWrapper();

    expect(findLink().attributes()).toMatchObject({
      href: '/help/user/project/merge_requests/merge_request_approvals',
      target: '_blank',
    });
    expect(findLink().text()).toBe('Learn more.');
  });

  it('renders an approval settings component', () => {
    createWrapper();

    expect(findApprovalSettings().exists()).toBe(true);
    expect(findApprovalSettings().props('approvalSettingsPath')).toBe(approvalSettingsPath);
  });
});
