import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import { isValidEnvironmentId } from './utils';
import SecurityPoliciesApp from './components/policies/policies_app.vue';
import createStore from './store';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default () => {
  const el = document.querySelector('#js-security-policies-list');
  const {
    assignedPolicyProject,
    disableSecurityPolicyProject,
    defaultEnvironmentId,
    environmentsEndpoint,
    emptyFilterSvgPath,
    emptyListSvgPath,
    documentationPath,
    newPolicyPath,
    projectPath,
  } = el.dataset;

  const environmentId = parseInt(defaultEnvironmentId, 10);
  // We require the project to have at least one available environment.
  // An invalid default environment id means there there are no available
  // environments, therefore infrastructure cannot be set up. A valid default
  // environment id only means that infrastructure *might* be set up.
  const hasEnvironment = isValidEnvironmentId(environmentId);

  const store = createStore();
  store.dispatch('threatMonitoring/setEnvironmentEndpoint', environmentsEndpoint);
  store.dispatch('threatMonitoring/setHasEnvironment', hasEnvironment);
  if (hasEnvironment) {
    store.dispatch('threatMonitoring/setCurrentEnvironmentId', environmentId);
  }

  return new Vue({
    apolloProvider,
    store,
    el,
    provide: {
      assignedPolicyProject: JSON.parse(assignedPolicyProject),
      disableSecurityPolicyProject: parseBoolean(disableSecurityPolicyProject),
      documentationPath,
      newPolicyPath,
      projectPath,
      emptyFilterSvgPath,
      emptyListSvgPath,
    },
    render(createElement) {
      return createElement(SecurityPoliciesApp);
    },
  });
};
