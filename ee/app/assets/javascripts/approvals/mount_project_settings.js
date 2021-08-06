import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import ProjectSettingsApp from './components/project_settings/app.vue';
import { projectApprovalsMappers } from './mappers';
import createStore from './stores';
import approvalSettingsModule from './stores/modules/approval_settings';
import projectSettingsModule from './stores/modules/project_settings';

export default function mountProjectSettingsApprovals(el) {
  if (!el) {
    return null;
  }

  const {
    vulnerabilityCheckHelpPagePath,
    licenseCheckHelpPagePath,
    coverageCheckHelpPagePath,
  } = el.dataset;

  const modules = {
    approvalSettings: approvalSettingsModule({ updateMethod: 'post', ...projectApprovalsMappers }),
    approvals: projectSettingsModule(),
  };

  const store = createStore(modules, {
    ...el.dataset,
    prefix: 'project-settings',
    allowMultiRule: parseBoolean(el.dataset.allowMultiRule),
    canEdit: parseBoolean(el.dataset.canEdit),
    canModifyAuthorSettings: parseBoolean(el.dataset.canModifyAuthorSettings),
    canModifyCommiterSettings: parseBoolean(el.dataset.canModifyCommiterSettings),
  });

  return new Vue({
    el,
    store,
    provide: {
      vulnerabilityCheckHelpPagePath,
      licenseCheckHelpPagePath,
      coverageCheckHelpPagePath,
    },
    render(h) {
      return h(ProjectSettingsApp);
    },
  });
}
