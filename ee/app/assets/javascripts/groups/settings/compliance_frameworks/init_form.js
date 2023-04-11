import Vue from 'vue';
import VueApollo from 'vue-apollo';

import createDefaultClient from '~/lib/graphql';
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
    provide: {
      graphqlFieldName,
      groupEditPath,
      groupPath,
      pipelineConfigurationFullPathEnabled: Boolean(pipelineConfigurationFullPathEnabled),
    },
    render(createElement) {
      let element = CreateForm;
      let props = {};

      if (id) {
        element = EditForm;
        props = { id };
      }

      return createElement(element, {
        props,
      });
    },
  });
};

export { createComplianceFrameworksFormApp };
