import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import SecurityPolicyProjectSelector from './components/security_policy_project_selector.vue';

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
    projectPath,
  } = el.dataset;

  const policyProject = JSON.parse(assignedPolicyProject);
  const props = policyProject ? { assignedPolicyProject: policyProject } : {};

  return new Vue({
    apolloProvider,
    el,
    provide: {
      disableSecurityPolicyProject: parseBoolean(disableSecurityPolicyProject),
      documentationPath,
      projectPath,
    },
    render(createElement) {
      return createElement(SecurityPolicyProjectSelector, {
        props,
      });
    },
  });
};
