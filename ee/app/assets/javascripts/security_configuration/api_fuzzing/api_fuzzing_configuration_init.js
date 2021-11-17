import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import ApiFuzzingApp from './components/app.vue';
import { apolloProvider } from './graphql/provider';

export const initApiFuzzingConfiguration = () => {
  const el = document.querySelector('.js-api-fuzzing-configuration');

  if (!el) {
    return undefined;
  }

  const {
    securityConfigurationPath,
    fullPath,
    gitlabCiYamlEditPath,
    apiFuzzingDocumentationPath,
    apiFuzzingAuthenticationDocumentationPath,
    ciVariablesDocumentationPath,
    projectCiSettingsPath,
  } = el.dataset;
  const canSetProjectCiVariables = parseBoolean(el.dataset.canSetProjectCiVariables);

  return new Vue({
    el,
    apolloProvider,
    provide: {
      securityConfigurationPath,
      fullPath,
      gitlabCiYamlEditPath,
      apiFuzzingDocumentationPath,
      apiFuzzingAuthenticationDocumentationPath,
      ciVariablesDocumentationPath,
      projectCiSettingsPath,
      canSetProjectCiVariables,
    },
    render(createElement) {
      return createElement(ApiFuzzingApp);
    },
  });
};
