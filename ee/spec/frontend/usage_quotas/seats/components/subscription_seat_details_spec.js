import { GlTable } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import Api from 'ee/api';
import SubscriptionSeatDetails from 'ee/usage_quotas/seats/components/subscription_seat_details.vue';
import SubscriptionSeatDetailsLoader from 'ee/usage_quotas/seats/components/subscription_seat_details_loader.vue';
import createStore from 'ee/usage_quotas/seats/store';
import initState from 'ee/usage_quotas/seats/store/state';
import { mockMemberDetails } from 'ee_jest/usage_quotas/seats/mock_data';
import { stubComponent } from 'helpers/stub_component';

Vue.use(Vuex);

describe('SubscriptionSeatDetails', () => {
  let wrapper;
  const actions = {
    fetchBillableMemberDetails: jest.fn(),
  };

  const createComponent = () => {
    const store = createStore(initState({ namespaceId: 1, isLoading: true }));

    wrapper = shallowMount(SubscriptionSeatDetails, {
      propsData: {
        seatMemberId: 1,
      },
      store: new Vuex.Store({ ...store, actions }),
      stubs: {
        GlTable: stubComponent(GlTable),
      },
    });
  };

  beforeEach(() => {
    Api.fetchBillableGroupMemberMemberships = jest.fn(() =>
      Promise.resolve({ data: mockMemberDetails }),
    );
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('on created', () => {
    it('calls fetchBillableMemberDetails', () => {
      expect(actions.fetchBillableMemberDetails).toHaveBeenCalledWith(expect.any(Object), 1);
    });

    it('displays skeleton loader', () => {
      expect(wrapper.findComponent(SubscriptionSeatDetailsLoader).isVisible()).toBe(true);
    });
  });
});
