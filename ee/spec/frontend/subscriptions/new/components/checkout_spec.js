import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import Checkout from 'ee/subscriptions/new/components/checkout.vue';
import createStore from 'ee/subscriptions/new/store';
import { mockTracking } from 'helpers/tracking_helper';
import SubscriptionDetails from 'ee/subscriptions/new/components/checkout/subscription_details.vue';
import { PurchaseEvent } from 'ee/subscriptions/new/constants';

Vue.use(Vuex);

describe('Checkout', () => {
  let trackingSpy;
  let wrapper;

  const findSubscriptionDetails = () => wrapper.findComponent(SubscriptionDetails);

  const createComponent = () => {
    trackingSpy = mockTracking(undefined, undefined, jest.spyOn);
    wrapper = shallowMount(Checkout, {
      store: createStore(),
    });
  };

  beforeEach(() => {
    createComponent();
  });

  describe('tracking', () => {
    it('tracks render on mount', () => {
      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'render', {
        label: 'saas_checkout',
      });
    });
  });

  describe('when the children component emits an error event', () => {
    it('emits an error event', () => {
      const error = new Error('Yikes!');
      findSubscriptionDetails().vm.$emit(PurchaseEvent.ERROR, error);

      expect(wrapper.emitted(PurchaseEvent.ERROR)).toEqual([[error]]);
    });
  });

  describe('when the children component emits an error-reset event', () => {
    it('emits an error event', () => {
      findSubscriptionDetails().vm.$emit(PurchaseEvent.ERROR_RESET);

      expect(wrapper.emitted(PurchaseEvent.ERROR_RESET)).toHaveLength(1);
    });
  });
});
