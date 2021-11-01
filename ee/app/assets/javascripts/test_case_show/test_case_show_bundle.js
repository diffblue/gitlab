import Vue from 'vue';
import VueApollo from 'vue-apollo';

import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';

import TestCaseShowApp from './components/test_case_show_root.vue';

Vue.use(VueApollo);

export default function initTestCaseShow({ mountPointSelector }) {
  const el = document.querySelector(mountPointSelector);

  if (!el) {
    return null;
  }

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  const sidebarOptions = JSON.parse(el.dataset.sidebarOptions);

  return new Vue({
    el,
    apolloProvider,
    provide: {
      ...el.dataset,
      projectsFetchPath: sidebarOptions.projectsAutocompleteEndpoint,
      canEditTestCase: parseBoolean(el.dataset.canEditTestCase),
      lockVersion: parseInt(el.dataset.lockVersion, 10),
    },
    render: (createElement) => createElement(TestCaseShowApp),
  });
}
