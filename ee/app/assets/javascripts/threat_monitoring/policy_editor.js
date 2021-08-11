import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import PolicyEditorApp from './components/policy_editor/policy_editor.vue';
import createStore from './store';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default () => {
  const el = document.querySelector('#js-policy-builder-app');
  const {
    environmentsEndpoint,
    configureAgentHelpPath,
    createAgentHelpPath,
    networkPoliciesEndpoint,
    threatMonitoringPath,
    policy,
    projectPath,
    projectId,
    environmentId,
  } = el.dataset;

  const store = createStore();
  store.dispatch('threatMonitoring/setEnvironmentEndpoint', environmentsEndpoint);
  store.dispatch('networkPolicies/setEndpoints', {
    networkPoliciesEndpoint,
  });

  if (environmentId !== undefined) {
    store.dispatch('threatMonitoring/setCurrentEnvironmentId', parseInt(environmentId, 10));
  }

  const props = policy ? { existingPolicy: JSON.parse(policy) } : {};

  return new Vue({
    el,
    apolloProvider,
    provide: {
      configureAgentHelpPath,
      createAgentHelpPath,
      projectId,
      projectPath,
      threatMonitoringPath,
    },
    store,
    render(createElement) {
      return createElement(PolicyEditorApp, { props });
    },
  });
};
