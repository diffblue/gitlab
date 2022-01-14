import Vue from 'vue';
import { returnToPreviousPageFactory } from 'ee/security_configuration/dast_profiles/redirect';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import DastSiteProfileForm from './components/dast_site_profile_form.vue';
import apolloProvider from './graphql/provider';

export default () => {
  const el = document.querySelector('.js-dast-site-profile-form');
  if (!el) {
    return;
  }

  const {
    projectFullPath,
    profilesLibraryPath,
    onDemandScanFormPath,
    dastConfigurationPath,
  } = el.dataset;

  const props = {};

  if (el.dataset.siteProfile) {
    props.profile = convertObjectPropsToCamelCase(JSON.parse(el.dataset.siteProfile));
  }

  const factoryParams = {
    allowedPaths: [onDemandScanFormPath, dastConfigurationPath],
    profilesLibraryPath,
    urlParamKey: 'site_profile_id',
  };

  // eslint-disable-next-line no-new
  new Vue({
    el,
    apolloProvider,
    provide: {
      projectFullPath,
    },
    render(h) {
      return h(DastSiteProfileForm, {
        props,
        on: {
          success: returnToPreviousPageFactory(factoryParams),
          cancel: returnToPreviousPageFactory(factoryParams),
        },
      });
    },
  });
};
