import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import SubscriptionApp from 'ee/billings/subscriptions/components/app.vue';
import initialStore from 'ee/billings/subscriptions/store';

Vue.use(Vuex);

describe('SubscriptionApp component', () => {
  let store;

  const providedFields = {
    namespaceId: '42',
    namespaceName: 'bronze',
    planRenewHref: '/url/for/renew',
    customerPortalUrl: 'https://customers.gitlab.com/subscriptions',
  };

  const factory = () => {
    store = new Vuex.Store(initialStore());
    jest.spyOn(store, 'dispatch').mockImplementation();

    shallowMount(SubscriptionApp, {
      store,
      provide: {
        ...providedFields,
      },
    });
  };

  describe('on creation', () => {
    beforeEach(() => {
      factory();
    });

    it('dispatches expected actions on created', () => {
      expect(store.dispatch.mock.calls).toEqual([['setNamespaceId', '42']]);
    });
  });
});
