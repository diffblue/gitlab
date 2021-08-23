import Vue from 'vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import OnDemandScansForm from './components/on_demand_scans_form.vue';
import apolloProvider from './graphql/provider';

export default () => {
  const el = document.querySelector('#js-on-demand-scans-app');
  if (!el) {
    return null;
  }

  const {
    dastSiteValidationDocsPath,
    projectPath,
    defaultBranch,
    profilesLibraryPath,
    scannerProfilesLibraryPath,
    siteProfilesLibraryPath,
    newSiteProfilePath,
    newScannerProfilePath,
    helpPagePath,
    dastScan,
  } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    provide: {
      projectPath,
      helpPagePath,
      profilesLibraryPath,
      scannerProfilesLibraryPath,
      siteProfilesLibraryPath,
      newScannerProfilePath,
      newSiteProfilePath,
      dastSiteValidationDocsPath,
    },
    render(h) {
      return h(OnDemandScansForm, {
        props: {
          defaultBranch,
          dastScan: dastScan ? convertObjectPropsToCamelCase(JSON.parse(dastScan)) : null,
        },
      });
    },
  });
};
