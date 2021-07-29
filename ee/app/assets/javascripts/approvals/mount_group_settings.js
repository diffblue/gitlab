import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import GroupSettingsApp from './components/group_settings/app.vue';
import { groupApprovalsMappers } from './mappers';
import createStore from './stores';
import approvalSettingsModule from './stores/modules/approval_settings';

const mountGroupApprovalSettings = (el) => {
  if (!el) {
    return null;
  }

  const { defaultExpanded, approvalSettingsPath } = el.dataset;
  const store = createStore({
    approvalSettings: approvalSettingsModule(groupApprovalsMappers),
  });

  return new Vue({
    el,
    store,
    render: (createElement) =>
      createElement(GroupSettingsApp, {
        props: {
          defaultExpanded: parseBoolean(defaultExpanded),
          approvalSettingsPath,
        },
      }),
  });
};

export { mountGroupApprovalSettings };
