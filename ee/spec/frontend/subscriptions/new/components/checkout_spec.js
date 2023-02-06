import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import Checkout from 'ee/subscriptions/new/components/checkout.vue';
import createStore from 'ee/subscriptions/new/store';
import { mockTracking } from 'helpers/tracking_helper';
import SubscriptionDetails from 'ee/subscriptions/new/components/checkout/subscription_details.vue';
import { createAlert } from '~/flash';
import { PurchaseEvent } from 'ee/subscriptions/new/constants';

const mockCreateAlert = {
  dismiss: jest.fn(),
};
jest.mock('~/flash', () => ({
  createAlert: jest.fn().mockImplementation(() => mockCreateAlert),
}));

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

  describe('when the children component emit events', () => {
    const error = new Error('Yikes!');

    describe('when the alert is not created yet', () => {
      it('dismisses the subscription details alert', () => {
        findSubscriptionDetails().vm.$emit(PurchaseEvent.ERROR_RESET);

        expect(mockCreateAlert.dismiss.mock.calls).toHaveLength(0);
      });
    });

    describe('when the alert is present', () => {
      beforeEach(() => {
        findSubscriptionDetails().vm.$emit(PurchaseEvent.ERROR, { message: 'A message', error });
      });

      it('creates an alert from subscription details error', () => {
        expect(createAlert).toHaveBeenCalledWith({
          message: 'A message',
          captureError: true,
          error,
        });
      });

      it('dismisses the subscription details alert', () => {
        findSubscriptionDetails().vm.$emit(PurchaseEvent.ERROR_RESET);

        expect(mockCreateAlert.dismiss.mock.calls).toHaveLength(1);
      });
    });
  });
});
