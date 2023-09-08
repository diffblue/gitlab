import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { parseBoolean } from '~/lib/utils/common_utils';
import SubscriptionSeats from 'ee/usage_quotas/seats/components/subscription_seats.vue';
import apolloProvider from './provider';
import initialStore from './store';

Vue.use(Vuex);

export default (containerId = 'js-seat-usage-app') => {
  const el = document.getElementById(containerId);

  if (!el) {
    return false;
  }

  const {
    fullPath,
    namespaceId,
    namespaceName,
    seatUsageExportPath,
    pendingMembersPagePath,
    pendingMembersCount,
    addSeatsHref,
    hasNoSubscription,
    maxFreeNamespaceSeats,
    explorePlansPath,
    enforcementFreeUserCapEnabled,
  } = el.dataset;

  return new Vue({
    el,
    name: 'SeatsUsageApp',
    apolloProvider,
    provide: {
      fullPath,
    },
    store: new Vuex.Store(
      initialStore({
        namespaceId,
        namespaceName,
        seatUsageExportPath,
        pendingMembersPagePath,
        pendingMembersCount,
        addSeatsHref,
        hasNoSubscription: parseBoolean(hasNoSubscription),
        maxFreeNamespaceSeats: parseInt(maxFreeNamespaceSeats, 10),
        explorePlansPath,
        enforcementFreeUserCapEnabled: parseBoolean(enforcementFreeUserCapEnabled),
      }),
    ),
    render(createElement) {
      return createElement(SubscriptionSeats);
    },
  });
};
