import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { createStore } from './store/edit';
import ProtectedEnvironmentsApp from './protected_environments_app.vue';

export const initProtectedEnvironments = () => {
  Vue.use(Vuex);

  const el = document.getElementById('js-protected-environments');

  if (!el) {
    return null;
  }

  const { projectId, apiLink, docsLink } = el.dataset;
  return new Vue({
    el,
    store: createStore({
      ...el.dataset,
    }),
    provide: {
      projectId,
      accessLevelsData: gon?.deploy_access_levels?.roles ?? [],
      apiLink,
      docsLink,
      searchUnprotectedEnvironmentsUrl: gon.search_unprotected_environments_url,
    },
    render(createElement) {
      return createElement(ProtectedEnvironmentsApp);
    },
  });
};
