import Vue from 'vue';
import VueApollo from 'vue-apollo';

import createDefaultClient from '~/lib/graphql';
import Form from './components/list.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

const createComplianceFrameworksListApp = (el) => {
  if (!el) {
    return false;
  }

  const { addFrameworkPath, editFrameworkPath, emptyStateSvgPath, groupPath } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    render(createElement) {
      return createElement(Form, {
        props: {
          addFrameworkPath,
          editFrameworkPath,
          emptyStateSvgPath,
          groupPath,
        },
      });
    },
  });
};

export { createComplianceFrameworksListApp };
