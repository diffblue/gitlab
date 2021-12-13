import Vue from 'vue';
import Vuex from 'vuex';
import PendingMembersApp from './components/app.vue';
import initialStore from './store';

Vue.use(Vuex);

export default (containerId = 'js-pending-members-app') => {
  const el = document.getElementById(containerId);

  if (!el) {
    return false;
  }

  const { namespaceId, namespaceName } = el.dataset;

  return new Vue({
    el,
    apolloProvider: {},
    store: new Vuex.Store(initialStore({ namespaceId, namespaceName })),
    render(createElement) {
      return createElement(PendingMembersApp);
    },
  });
};
