import Vue from 'vue';
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
  } = el.dataset;
  const dastScan = el.dataset.dastScan ? JSON.parse(el.dataset.dastScan) : null;
  const timezones = JSON.parse(el.dataset.timezones);

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
      timezones,
    },
    render(h) {
      return h(OnDemandScansForm, {
        props: {
          defaultBranch,
          dastScan,
        },
      });
    },
  });
};
