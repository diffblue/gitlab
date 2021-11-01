import Vue from 'vue';
import VueApollo from 'vue-apollo';

import createDefaultClient from '~/lib/graphql';

import TestCaseCreateApp from './components/test_case_create_root.vue';

Vue.use(VueApollo);

export function initTestCaseCreate({ mountPointSelector }) {
  const mountPointEl = document.querySelector(mountPointSelector);

  if (!mountPointEl) {
    return null;
  }

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el: mountPointEl,
    apolloProvider,
    provide: {
      ...mountPointEl.dataset,
    },
    render: (createElement) => createElement(TestCaseCreateApp),
  });
}
