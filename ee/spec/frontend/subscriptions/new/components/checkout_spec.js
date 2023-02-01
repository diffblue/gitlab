import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import Checkout from 'ee/subscriptions/new/components/checkout.vue';
import createStore from 'ee/subscriptions/new/store';
import { mockTracking } from 'helpers/tracking_helper';
import ConfirmOrder from 'ee/subscriptions/new/components/checkout/confirm_order.vue';
import SubscriptionDetails, {
  Event,
} from 'ee/subscriptions/new/components/checkout/subscription_details.vue';
import { createAlert } from '~/flash';
import { GENERAL_ERROR_MESSAGE } from 'ee/vue_shared/purchase_flow/constants';

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

  const findConfirmOrder = () => wrapper.findComponent(ConfirmOrder);
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

    it('creates an alert from subscription details error', () => {
      findSubscriptionDetails().vm.$emit(Event.ERROR, { message: 'A message', error });

      expect(createAlert).toHaveBeenCalledWith({
        message: 'A message',
        captureError: true,
        error,
      });
    });

    it('dismisses the subscription details alert', () => {
      findSubscriptionDetails().vm.$emit(Event.ERROR, { message: 'A message', error });

      findSubscriptionDetails().vm.$emit(Event.ERROR_RESET);

      expect(mockCreateAlert.dismiss.mock.calls).toHaveLength(1);
    });

    it('creates an alert from confirm order error', () => {
      findConfirmOrder().vm.$emit('error', { error });

      expect(createAlert).toHaveBeenCalledWith({
        message: GENERAL_ERROR_MESSAGE,
        captureError: true,
        error,
      });
    });
  });
});
