import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { helpPagePath } from '~/helpers/help_page_helper';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import CloudLicenseShowApp from './components/app.vue';
import initialStore from './store';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default () => {
  const el = document.getElementById('js-show-subscription-page');

  if (!el) {
    return null;
  }

  const {
    buySubscriptionPath,
    congratulationSvgPath,
    customersPortalUrl,
    freeTrialPath,
    hasActiveLicense,
    licenseRemovePath,
    subscriptionActivationBannerCalloutName,
    subscriptionSyncPath,
    licenseUsageFilePath,
  } = el.dataset;
  const connectivityHelpURL = helpPagePath('/user/admin_area/license.html', {
    anchor: 'cannot-activate-instance-due-to-connectivity-error',
  });

  return new Vue({
    el,
    store: initialStore({ licenseRemovalPath: licenseRemovePath, subscriptionSyncPath }),
    name: 'CloudLicenseRoot',
    apolloProvider,
    provide: {
      buySubscriptionPath,
      congratulationSvgPath,
      connectivityHelpURL,
      customersPortalUrl,
      freeTrialPath,
      licenseRemovePath,
      subscriptionActivationBannerCalloutName,
      subscriptionSyncPath,
    },
    render: (h) =>
      h(CloudLicenseShowApp, {
        props: {
          hasActiveLicense: parseBoolean(hasActiveLicense),
          licenseUsageFilePath,
        },
      }),
  });
};
