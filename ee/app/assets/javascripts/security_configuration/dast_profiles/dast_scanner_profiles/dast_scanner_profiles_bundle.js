import Vue from 'vue';
import { returnToPreviousPageFactory } from 'ee/security_configuration/dast_profiles/redirect';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import DastScannerProfileForm from './components/dast_scanner_profile_form.vue';
import apolloProvider from './graphql/provider';

export default () => {
  const el = document.querySelector('.js-dast-scanner-profile-form');
  if (!el) {
    return false;
  }

  const {
    projectFullPath,
    profilesLibraryPath,
    onDemandScanFormPath,
    dastConfigurationPath,
  } = el.dataset;

  const props = {};

  if (el.dataset.scannerProfile) {
    props.profile = convertObjectPropsToCamelCase(JSON.parse(el.dataset.scannerProfile));
  }

  const factoryParams = {
    allowedPaths: [onDemandScanFormPath, dastConfigurationPath],
    profilesLibraryPath,
    urlParamKey: 'scanner_profile_id',
  };

  return new Vue({
    el,
    apolloProvider,
    provide: {
      projectFullPath,
    },
    render(h) {
      return h(DastScannerProfileForm, {
        props,
        on: {
          success: returnToPreviousPageFactory(factoryParams),
          cancel: returnToPreviousPageFactory(factoryParams),
        },
      });
    },
  });
};
