import { GlSprintf, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import Vue from 'vue';
import Vuex from 'vuex';

import ApprovalSettings from 'ee/approvals/components/approval_settings.vue';
import GroupSettingsApp from 'ee/approvals/components/group_settings/app.vue';
import { GROUP_APPROVAL_SETTINGS_LABELS_I18N } from 'ee/approvals/constants';
import { mergeRequestApprovalSettingsMappers } from 'ee/approvals/mappers';
import { createStoreOptions } from 'ee/approvals/stores';
import approvalSettingsModule from 'ee/approvals/stores/modules/approval_settings';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import SettingsBlock from '~/vue_shared/components/settings/settings_block.vue';

Vue.use(Vuex);

describe('EE Approvals Group Settings App', () => {
  let wrapper;
  let store;
  let axiosMock;

  const defaultExpanded = true;
  const approvalSettingsPath = 'groups/22/merge_request_approval_settings';

  const createWrapper = () => {
    wrapper = extendedWrapper(
      shallowMount(GroupSettingsApp, {
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
      }),
    );
  };

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);
    axiosMock.onGet('*');

    store = createStoreOptions({
      approvalSettings: approvalSettingsModule(mergeRequestApprovalSettingsMappers),
    });
  });

  afterEach(() => {
    store = null;
  });

  const findSettingsBlock = () => wrapper.findComponent(SettingsBlock);
  const findDescriptionLink = () => wrapper.findByTestId('group-settings-description');
  const findLearnMoreLink = () => wrapper.findByTestId('group-settings-learn-more');
  const findApprovalSettings = () => wrapper.findComponent(ApprovalSettings);

  it('renders a settings block', () => {
    createWrapper();

    expect(findSettingsBlock().exists()).toBe(true);
    expect(findSettingsBlock().props('defaultExpanded')).toBe(true);
  });

  it.each`
    findComponent          | text                      | href
    ${findDescriptionLink} | ${'separation of duties'} | ${'/help/user/compliance/compliance_report/index#separation-of-duties'}
    ${findLearnMoreLink}   | ${'Learn more.'}          | ${'/help/user/project/merge_requests/approvals/index.md'}
  `('has the correct link for $text', ({ findComponent, text, href }) => {
    createWrapper();

    expect(findComponent().attributes()).toMatchObject({ href, target: '_blank' });
    expect(findComponent().text()).toBe(text);
  });

  it('renders an approval settings component', () => {
    createWrapper();

    expect(findApprovalSettings().exists()).toBe(true);
    expect(findApprovalSettings().props()).toMatchObject({
      approvalSettingsPath,
      settingsLabels: GROUP_APPROVAL_SETTINGS_LABELS_I18N,
    });
  });
});
