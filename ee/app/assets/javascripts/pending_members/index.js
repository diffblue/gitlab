import Vue from 'vue';
import Vuex from 'vuex';
import { parseBoolean } from '~/lib/utils/common_utils';
import PendingMembersApp from './components/app.vue';
import initialStore from './store';

Vue.use(Vuex);

export default (containerId = 'js-pending-members-app') => {
  const el = document.getElementById(containerId);

  if (!el) {
    return false;
  }

  const { namespaceId, namespaceName, userCapSet } = el.dataset;

  return new Vue({
    el,
    apolloProvider: {},
    store: new Vuex.Store(
      initialStore({ namespaceId, namespaceName, userCapSet: parseBoolean(userCapSet) }),
    ),
    render(createElement) {
      return createElement(PendingMembersApp);
    },
  });
};
