import Vue from 'vue';
import DastProfiles from './components/dast_profiles.vue';
import apolloProvider from './graphql/provider';

export default () => {
  const el = document.querySelector('.js-dast-profiles');

  if (!el) {
    return undefined;
  }

  const {
    dataset: {
      newDastSavedScanPath,
      newDastScannerProfilePath,
      newDastSiteProfilePath,
      projectFullPath,
      timezones,
    },
  } = el;

  const props = {
    createNewProfilePaths: {
      savedScan: newDastSavedScanPath,
      scannerProfile: newDastScannerProfilePath,
      siteProfile: newDastSiteProfilePath,
    },
    projectFullPath,
  };

  return new Vue({
    el,
    apolloProvider,
    provide: {
      timezones: JSON.parse(timezones),
    },
    render(h) {
      return h(DastProfiles, {
        props,
      });
    },
  });
};
