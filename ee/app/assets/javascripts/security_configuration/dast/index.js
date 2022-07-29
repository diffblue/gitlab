import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import DastConfigurationApp from './components/app.vue';

export default function init() {
  const el = document.querySelector('.js-dast-configuration');

  if (!el) {
    return undefined;
  }

  Vue.use(VueApollo);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  const {
    securityConfigurationPath,
    fullPath,
    gitlabCiYamlEditPath,
    siteProfilesLibraryPath,
    scannerProfilesLibraryPath,
    newScannerProfilePath,
    newSiteProfilePath,
    pipelineCreatedAt,
    pipelineId,
    pipelinePath,
    scannerProfile,
    siteProfile,
  } = el.dataset;

  const dastEnabled = 'dastEnabled' in el.dataset;

  return new Vue({
    el,
    apolloProvider,
    provide: {
      securityConfigurationPath,
      projectPath: fullPath,
      gitlabCiYamlEditPath,
      siteProfilesLibraryPath,
      scannerProfilesLibraryPath,
      newScannerProfilePath,
      newSiteProfilePath,
      dastEnabled,
      pipelineCreatedAt,
      pipelineId,
      pipelinePath,
      scannerProfile,
      siteProfile,
    },
    render(createElement) {
      return createElement(DastConfigurationApp);
    },
  });
}
