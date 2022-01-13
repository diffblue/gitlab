import Vue from 'vue';
import Vuex from 'vuex';
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
    planRenewHref,
    customerPortalUrl,
    billableSeatsHref,
    planName,
    refreshSeatsHref,
    action,
    trialPlanName,
  } = containerEl.dataset;

  return new Vue({
    el: containerEl,
    store: new Vuex.Store(initialStore()),
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
    },
    render(createElement) {
      return createElement(SubscriptionApp);
    },
  });
};
