import Vue from 'vue';
import OnDemandScansForm from './components/on_demand_scans_form.vue';
import apolloProvider from './graphql/provider';

export default () => {
  const el = document.querySelector('#js-on-demand-scans-form');
  if (!el) {
    return null;
  }

  const {
    projectPath,
    defaultBranch,
    profilesLibraryPath,
    scannerProfilesLibraryPath,
    siteProfilesLibraryPath,
    newSiteProfilePath,
    newScannerProfilePath,
  } = el.dataset;
  const dastScan = el.dataset.dastScan ? JSON.parse(el.dataset.dastScan) : null;
  const timezones = JSON.parse(el.dataset.timezones);

  return new Vue({
    el,
    apolloProvider,
    provide: {
      projectPath,
      profilesLibraryPath,
      scannerProfilesLibraryPath,
      siteProfilesLibraryPath,
      newScannerProfilePath,
      newSiteProfilePath,
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
