import Vue from 'vue';
import VueApollo from 'vue-apollo';

import createDefaultClient from '~/lib/graphql';
import Table from './components/table.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

const createComplianceFrameworksTableApp = (el) => {
  if (!el) {
    return false;
  }

  const {
    addFrameworkPath,
    editFrameworkPath,
    emptyStateSvgPath,
    graphqlFieldName = null,
    groupPath,
    groupEditPath,
    pipelineConfigurationFullPathEnabled,
  } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    provide: {
      graphqlFieldName,
      groupEditPath,
      groupPath,
      pipelineConfigurationFullPathEnabled: Boolean(pipelineConfigurationFullPathEnabled),
    },
    render(createElement) {
      return createElement(Table, {
        props: {
          addFrameworkPath,
          editFrameworkPath,
          emptyStateSvgPath,
        },
      });
    },
  });
};

export { createComplianceFrameworksTableApp };
