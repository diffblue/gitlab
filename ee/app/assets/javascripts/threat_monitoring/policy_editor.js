import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { convertObjectPropsToCamelCase, parseBoolean } from '~/lib/utils/common_utils';
import PolicyEditorApp from './components/policy_editor/policy_editor.vue';
import { DEFAULT_ASSIGNED_POLICY_PROJECT } from './constants';
import createStore from './store';
import { gqClient, isValidEnvironmentId } from './utils';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: gqClient,
});

export default () => {
  const el = document.querySelector('#js-policy-builder-app');
  const {
    assignedPolicyProject,
    defaultEnvironmentId,
    disableScanPolicyUpdate,
    environmentsEndpoint,
    createAgentHelpPath,
    networkPoliciesEndpoint,
    networkDocumentationPath,
    policiesPath,
    policy,
    policyEditorEmptyStateSvgPath,
    policyType,
    projectPath,
    projectId,
    environmentId,
    scanPolicyDocumentationPath,
    scanResultApprovers,
  } = el.dataset;

  // We require the project to have at least one available environment.
  // An invalid default environment id means there there are no available
  // environments, therefore infrastructure cannot be set up. A valid default
  // environment id only means that infrastructure *might* be set up.
  const hasEnvironment = isValidEnvironmentId(parseInt(defaultEnvironmentId, 10));

  const store = createStore();
  store.dispatch('threatMonitoring/setEnvironmentEndpoint', environmentsEndpoint);
  store.dispatch('networkPolicies/setEndpoints', {
    networkPoliciesEndpoint,
  });
  store.dispatch('threatMonitoring/setHasEnvironment', hasEnvironment);
  if (hasEnvironment && environmentId !== undefined) {
    store.dispatch('threatMonitoring/setCurrentEnvironmentId', parseInt(environmentId, 10));
  }

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

  return new Vue({
    el,
    apolloProvider,
    provide: {
      createAgentHelpPath,
      disableScanPolicyUpdate: parseBoolean(disableScanPolicyUpdate),
      networkDocumentationPath,
      policyEditorEmptyStateSvgPath,
      policyType,
      projectId,
      projectPath,
      policiesPath,
      scanPolicyDocumentationPath,
      scanResultPolicyApprovers,
    },
    store,
    render(createElement) {
      return createElement(PolicyEditorApp, { props });
    },
  });
};
