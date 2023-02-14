import Vue from 'vue';
import CreateProtectedEnvironment from './create_protected_environment.vue';

export const initProtectedEnvironmentCreate = () => {
  const el = document.querySelector('.js-protected-environment-create-form');
  if (!el) {
    return null;
  }

  const { projectId, apiLink, docsLink } = el.dataset;
  return new Vue({
    el,
    provide: {
      accessLevelsData: gon?.deploy_access_levels?.roles ?? [],
      apiLink,
      docsLink,
    },
    render(h) {
      return h(CreateProtectedEnvironment, {
        props: {
          projectId,
          searchUnprotectedEnvironmentsUrl: gon.search_unprotected_environments_url,
        },
      });
    },
  });
};
