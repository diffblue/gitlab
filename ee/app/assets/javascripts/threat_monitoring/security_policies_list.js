import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import SecurityPoliciesApp from './components/policies/policies_app.vue';
import createStore from './store';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient({}, { assumeImmutableResults: true }),
});

export default () => {
  const el = document.querySelector('#js-security-policies-list');
  const {
    assignedPolicyProject,
    disableSecurityPolicyProject,
    defaultEnvironmentId,
    environmentsEndpoint,
    emptyStateSvgPath,
    documentationPath,
    newPolicyPath,
    projectPath,
  } = el.dataset;

  const store = createStore();
  store.dispatch('threatMonitoring/setEnvironmentEndpoint', environmentsEndpoint);

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
      emptyStateSvgPath,
      defaultEnvironmentId: parseInt(defaultEnvironmentId, 10),
    },
    render(createElement) {
      return createElement(SecurityPoliciesApp);
    },
  });
};
