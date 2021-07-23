import Vue from 'vue';
import Vuex from 'vuex';
import { parseBoolean } from '~/lib/utils/common_utils';
import SubscriptionApp from './components/app.vue';
import initialStore from './store';

Vue.use(Vuex);

export default (containerId = 'js-billing-plans') => {
  const containerEl = document.getElementById(containerId);

  if (!containerEl) {
    return false;
  }

  const {
    namespaceId,
    namespaceName,
    addSeatsHref,
    planUpgradeHref,
    planRenewHref,
    customerPortalUrl,
    billableSeatsHref,
    planName,
    freePersonalNamespace,
    refreshSeatsHref,
  } = containerEl.dataset;

  return new Vue({
    el: containerEl,
    store: new Vuex.Store(initialStore()),
    provide: {
      namespaceId,
      namespaceName,
      addSeatsHref,
      planUpgradeHref,
      planRenewHref,
      customerPortalUrl,
      billableSeatsHref,
      planName,
      freePersonalNamespace: parseBoolean(freePersonalNamespace),
      refreshSeatsHref,
    },
    render(createElement) {
      return createElement(SubscriptionApp);
    },
  });
};
