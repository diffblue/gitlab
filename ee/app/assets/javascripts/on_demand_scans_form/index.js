import Vue from 'vue';
import apolloProvider from 'ee/vue_shared/security_configuration/graphql/provider';
import OnDemandScansForm from './components/on_demand_scans_form.vue';

export default () => {
  const el = document.querySelector('#js-on-demand-scans-form');
  if (!el) {
    return null;
  }

  const {
    projectPath,
    defaultBranch,
    onDemandScansPath,
    scannerProfilesLibraryPath,
    siteProfilesLibraryPath,
    newSiteProfilePath,
    newScannerProfilePath,
  } = el.dataset;
  const dastScan = el.dataset.dastScan ? JSON.parse(el.dataset.dastScan) : null;
  const timezones = JSON.parse(el.dataset.timezones);

  return new Vue({
    el,
    name: 'OnDemandScansFormRoot',
    apolloProvider,
    provide: {
      projectPath,
      onDemandScansPath,
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
