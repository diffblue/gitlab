import { GlTableLite } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
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

  const createComponent = ({ initialUserDetails } = { initialUserDetails: {} }) => {
    const seatMemberId = 1;
    const store = createStore(initState({ namespaceId: 1 }));
    store.state = {
      ...store.state,
      userDetails: {
        [seatMemberId]: {
          isLoading: false,
          hasError: false,
          items: mockMemberDetails,
          ...initialUserDetails,
        },
      },
    };

    wrapper = shallowMount(SubscriptionSeatDetails, {
      propsData: {
        seatMemberId,
      },
      store: new Vuex.Store({ ...store, actions }),
      stubs: {
        GlTableLite: stubComponent(GlTableLite),
      },
    });
  };

  describe('on created', () => {
    beforeEach(() => {
      createComponent();
    });

    it('calls fetchBillableMemberDetails', () => {
      expect(actions.fetchBillableMemberDetails).toHaveBeenCalledWith(expect.any(Object), 1);
    });
  });

  describe('loading state', () => {
    beforeEach(() => {
      createComponent({
        initialUserDetails: {
          isLoading: true,
        },
      });
    });

    it('displays skeleton loader', () => {
      expect(wrapper.findComponent(SubscriptionSeatDetailsLoader).isVisible()).toBe(true);
    });
  });

  describe('error state', () => {
    beforeEach(() => {
      createComponent({
        initialUserDetails: {
          isLoading: false,
          hasError: true,
        },
      });
    });

    it('displays skeleton loader', () => {
      expect(wrapper.findComponent(SubscriptionSeatDetailsLoader).isVisible()).toBe(true);
    });
  });
});
