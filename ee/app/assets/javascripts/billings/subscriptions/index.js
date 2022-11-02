import Vue from 'vue';
import Vuex from 'vuex';
import { parseBoolean } from '~/lib/utils/common_utils';
import SubscriptionApp from './components/app.vue';
import initialStore from './store';
import apolloProvider from './provider';

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
    planRenewHref,
    customerPortalUrl,
    billableSeatsHref,
    planName,
    refreshSeatsHref,
    action,
    trialPlanName,
    readOnly,
  } = containerEl.dataset;

  return new Vue({
    el: containerEl,
    store: new Vuex.Store(initialStore()),
    apolloProvider,
    provide: {
      namespaceId: Number(namespaceId),
      namespaceName,
      addSeatsHref,
      planRenewHref,
      customerPortalUrl,
      billableSeatsHref,
      planName,
      refreshSeatsHref,
      availableTrialAction: action,
      trialPlanName,
      readOnly: parseBoolean(readOnly),
    },
    render(createElement) {
      return createElement(SubscriptionApp);
    },
  });
};
