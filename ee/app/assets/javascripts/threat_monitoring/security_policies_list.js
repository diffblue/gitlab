import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import SecurityPoliciesApp from './components/policies/policies_app.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default (el, namespaceType) => {
  const {
    assignedPolicyProject,
    disableSecurityPolicyProject,
    emptyFilterSvgPath,
    emptyListSvgPath,
    documentationPath,
    groupPath,
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
      emptyFilterSvgPath,
      emptyListSvgPath,
      groupPath,
      namespaceType,
    },
    render(createElement) {
      return createElement(SecurityPoliciesApp);
    },
  });
};
