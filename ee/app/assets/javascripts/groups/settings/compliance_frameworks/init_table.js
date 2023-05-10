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
    canAddEdit,
    emptyStateSvgPath,
    graphqlFieldName = null,
    groupPath,
    pipelineConfigurationFullPathEnabled,
  } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    provide: {
      canAddEdit,
      graphqlFieldName,
      groupPath,
      pipelineConfigurationFullPathEnabled: Boolean(pipelineConfigurationFullPathEnabled),
    },
    render(createElement) {
      return createElement(Table, {
        props: {
          emptyStateSvgPath,
        },
      });
    },
  });
};

export { createComplianceFrameworksTableApp };
