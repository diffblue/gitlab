import Vue from 'vue';
import VueApollo from 'vue-apollo';

import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import CreateForm from './components/create_form.vue';
import EditForm from './components/edit_form.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

const createComplianceFrameworksFormApp = (el) => {
  if (!el) {
    return false;
  }

  const {
    groupEditPath,
    groupPath,
    pipelineConfigurationFullPathEnabled,
    graphqlFieldName = null,
    frameworkId: id = null,
  } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    render(createElement) {
      let element = CreateForm;
      let props = {
        groupEditPath,
        groupPath,
        pipelineConfigurationFullPathEnabled: parseBoolean(pipelineConfigurationFullPathEnabled),
      };

      if (id) {
        element = EditForm;
        props = { ...props, graphqlFieldName, id };
      }

      return createElement(element, {
        props,
      });
    },
  });
};

export { createComplianceFrameworksFormApp };
