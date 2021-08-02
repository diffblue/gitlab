import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import SecurityPoliciesApp from './components/policies/policies_app.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient({}, { assumeImmutableResults: true }),
});

export default () => {
  const el = document.querySelector('#js-security-policies-list');
  const {
    assignedPolicyProject,
    disableSecurityPolicyProject,
    documentationPath,
    newPolicyPath,
    projectPath,
  } = el.dataset;

  return new Vue({
    apolloProvider,
    el,
    provide: {
      assignedPolicyProject: JSON.parse(assignedPolicyProject),
      disableSecurityPolicyProject: parseBoolean(disableSecurityPolicyProject),
      documentationPath,
      newPolicyPath,
      projectPath,
    },
    render(createElement) {
      return createElement(SecurityPoliciesApp);
    },
  });
};
