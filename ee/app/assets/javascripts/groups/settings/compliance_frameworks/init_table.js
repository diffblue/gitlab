import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { parseFormProps } from './utils';
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
    graphqlFieldName,
    groupPath,
    pipelineConfigurationFullPathEnabled,
    pipelineConfigurationEnabled,
  } = parseFormProps(el.dataset);

  return new Vue({
    el,
    apolloProvider,
    provide: {
      canAddEdit,
      graphqlFieldName,
      groupPath,
      pipelineConfigurationFullPathEnabled,
      pipelineConfigurationEnabled,
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
