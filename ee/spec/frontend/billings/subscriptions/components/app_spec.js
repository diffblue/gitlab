import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import SubscriptionApp from 'ee/billings/subscriptions/components/app.vue';
import initialStore from 'ee/billings/subscriptions/store';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('SubscriptionApp component', () => {
  let store;
  let wrapper;

  const providedFields = {
    namespaceId: '42',
    namespaceName: 'bronze',
    planRenewHref: '/url/for/renew',
    customerPortalUrl: 'https://customers.gitlab.com/subscriptions',
  };

  const factory = () => {
    store = new Vuex.Store(initialStore());
    jest.spyOn(store, 'dispatch').mockImplementation();

    wrapper = shallowMount(SubscriptionApp, {
      store,
      provide: {
        ...providedFields,
      },
      localVue,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('on creation', () => {
    beforeEach(() => {
      factory();
    });

    it('dispatches expected actions on created', () => {
      expect(store.dispatch.mock.calls).toEqual([['setNamespaceId', '42']]);
    });
  });
});
