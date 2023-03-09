import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import Vuex from 'vuex';
import Zuora from 'ee/subscriptions/new/components/checkout/zuora.vue';
import { mockTracking } from 'helpers/tracking_helper';
import { STEPS } from 'ee/subscriptions/constants';
import PaymentMethod from 'ee/subscriptions/new/components/checkout/payment_method.vue';
import createStore from 'ee/subscriptions/new/store';
import * as types from 'ee/subscriptions/new/store/mutation_types';
import Step from 'ee/vue_shared/purchase_flow/components/step.vue';
import { createMockApolloProvider } from 'ee_jest/vue_shared/purchase_flow/spec_helper';

describe('Payment Method', () => {
  Vue.use(Vuex);
  Vue.use(VueApollo);

  let store;
  let wrapper;

  function createComponent(options = {}) {
    return mount(PaymentMethod, {
      store,
      ...options,
    });
  }

  beforeEach(() => {
    store = createStore();

    store.commit(types.UPDATE_PAYMENT_METHOD_ID, 'paymentMethodId');
    store.commit(types.UPDATE_CREDIT_CARD_DETAILS, {
      credit_card_type: 'Visa',
      credit_card_mask_number: '************4242',
      credit_card_expiration_month: 12,
      credit_card_expiration_year: 2009,
    });

    const mockApollo = createMockApolloProvider(STEPS);
    wrapper = createComponent({ apolloProvider: mockApollo });
  });

  describe('validations', () => {
    const isStepValid = () => wrapper.findComponent(Step).props('isValid');

    it('should be valid when paymentMethodId is defined', () => {
      expect(isStepValid()).toBe(true);
    });

    it('should be invalid when paymentMethodId is undefined', async () => {
      store.commit(types.UPDATE_PAYMENT_METHOD_ID, null);

      await nextTick();
      expect(isStepValid()).toBe(false);
    });
  });

  describe('showing the summary', () => {
    it('should show the entered credit card details', () => {
      expect(wrapper.find('.js-summary-line-1').html().replace(/\s+/g, ' ')).toContain(
        'Visa ending in <strong>4242</strong>',
      );
    });

    it('should show the entered credit card expiration date', () => {
      expect(wrapper.find('.js-summary-line-2').text()).toEqual('Exp 12/09');
    });
  });

  describe('tracking', () => {
    it('tracks step completion details', async () => {
      const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

      wrapper.findComponent(Zuora).vm.$emit('success');
      await nextTick();

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_button', {
        label: 'review_order',
        property: 'Success',
      });
    });

    it('tracks zuora errors on step transition', async () => {
      const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

      wrapper.findComponent(Zuora).vm.$emit('error', 'This was a mistake.');
      await nextTick();

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_button', {
        label: 'review_order',
        property: 'This was a mistake.',
      });
    });

    it('tracks step edits', async () => {
      const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

      wrapper.findComponent(Step).vm.$emit('stepEdit', 'stepID');
      await nextTick();

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_button', {
        label: 'edit',
        property: 'paymentMethod',
      });
    });
  });
});
