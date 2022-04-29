import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { convertObjectPropsToCamelCase, parseBoolean } from '~/lib/utils/common_utils';
import PolicyEditorApp from './components/policy_editor/policy_editor.vue';
import NewPolicyApp from './components/policy_editor/new_policy.vue';
import { DEFAULT_ASSIGNED_POLICY_PROJECT } from './constants';
import { gqClient } from './utils';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: gqClient,
});

export default (el, namespaceType) => {
  const {
    assignedPolicyProject,
    disableScanPolicyUpdate,
    createAgentHelpPath,
    policiesPath,
    policy,
    policyEditorEmptyStateSvgPath,
    policyType,
    projectPath,
    projectId,
    scanPolicyDocumentationPath,
    scanResultApprovers,
  } = el.dataset;

  const policyProject = JSON.parse(assignedPolicyProject);
  const props = {
    assignedPolicyProject: policyProject
      ? convertObjectPropsToCamelCase(policyProject)
      : DEFAULT_ASSIGNED_POLICY_PROJECT,
  };

  if (policy) {
    props.existingPolicy = { type: policyType, ...JSON.parse(policy) };
  }

  const scanResultPolicyApprovers = scanResultApprovers ? JSON.parse(scanResultApprovers) : [];

  let component = PolicyEditorApp;

  if (gon.features?.containerSecurityPolicySelection) {
    component = NewPolicyApp;
  }

  return new Vue({
    el,
    apolloProvider,
    provide: {
      createAgentHelpPath,
      disableScanPolicyUpdate: parseBoolean(disableScanPolicyUpdate),
      namespaceType,
      policyEditorEmptyStateSvgPath,
      policyType,
      projectId,
      projectPath,
      policiesPath,
      scanPolicyDocumentationPath,
      scanResultPolicyApprovers,
    },
    render(createElement) {
      return createElement(component, { props });
    },
  });
};
