import Vue from 'vue';
import Vuex from 'vuex';
import SubscriptionSeats from './components/subscription_seats.vue';
import initialStore from './store';

Vue.use(Vuex);

export default (containerId = 'js-seat-usage-app') => {
  const el = document.getElementById(containerId);

  if (!el) {
    return false;
  }

  const { namespaceId, namespaceName, seatUsageExportPath } = el.dataset;

  return new Vue({
    el,
    apolloProvider: {},
    store: new Vuex.Store(initialStore({ namespaceId, namespaceName, seatUsageExportPath })),
    render(createElement) {
      return createElement(SubscriptionSeats);
    },
  });
};
