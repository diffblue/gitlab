import Vue, { nextTick } from 'vue';
import * as Sentry from '@sentry/browser';
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import Component from 'ee/subscriptions/new/components/app.vue';
import OrderSummary from 'ee/subscriptions/new/components/order_summary.vue';
import Checkout from 'ee/subscriptions/new/components/checkout.vue';
import GitlabExperiment from '~/experimentation/components/gitlab_experiment.vue';
import { PurchaseEvent } from 'ee/subscriptions/new/constants';
import ErrorAlert from 'ee/vue_shared/purchase_flow/components/checkout/error_alert.vue';
import initialStore from 'ee/subscriptions/new/store';

Vue.use(Vuex);

describe('App component', () => {
  let wrapper;
  let store;

  const findCheckout = () => wrapper.findComponent(Checkout);
  const findConfirmOrderDesktop = () => wrapper.findByTestId('confirm-order-desktop');
  const findConfirmOrderMobile = () => wrapper.findByTestId('confirm-order-mobile');
  const findErrorAlert = () => wrapper.findComponent(ErrorAlert);
  const findOrderSummary = () => wrapper.findComponent(OrderSummary);

  const createComponent = () => {
    store = new Vuex.Store({
      ...initialStore,
      actions: {
        confirmOrderError: jest.fn(),
        fakeAction: jest.fn(),
      },
    });

    wrapper = shallowMountExtended(Component, {
      store,
      stubs: {
        GitlabExperiment,
        StepOrderApp: {
          template: `
            <div>
                <slot name="checkout"></slot>
                <slot name="order-summary"></slot>
            </div>
            `,
        },
      },
    });
  };

  beforeEach(() => {
    jest.spyOn(Sentry, 'captureException');
  });

  describe('step order app', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders checkout', () => {
      expect(findCheckout().exists()).toBe(true);
    });

    it('renders OrderSummary', () => {
      expect(findOrderSummary().exists()).toBe(true);
    });
  });

  describe('confirm order CTA', () => {
    it(`should show confirm order CTA`, async () => {
      createComponent();

      await nextTick();

      expect(findConfirmOrderDesktop().classes()).toEqual([
        'gl-display-none',
        'gl-lg-display-block!',
      ]);

      expect(findConfirmOrderMobile().classes()).toEqual([
        'gl-display-block',
        'gl-lg-display-none!',
      ]);
    });
  });

  describe('when the store dispatches events', () => {
    const errorMessage = 'Yikes!';
    const error = new Error(errorMessage);

    describe(`with the 'confirmOrderError'`, () => {
      beforeEach(() => {
        createComponent();

        store.dispatch('confirmOrderError', error);
      });

      it('passes the correct props', () => {
        expect(findErrorAlert().props('error')).toStrictEqual(error);
      });

      it('captures the error', () => {
        expect(Sentry.captureException.mock.calls[0][0]).toStrictEqual(error);
      });
    });

    describe('with any other action', () => {
      beforeEach(() => {
        createComponent();

        store.dispatch('fakeAction');
      });

      it('does not the alert', () => {
        expect(findErrorAlert().exists()).toBe(false);
      });
    });
  });

  describe('when the children component emit events', () => {
    const error = new Error('Yikes!');

    describe.each([
      findCheckout,
      findConfirmOrderDesktop,
      findConfirmOrderDesktop,
      findConfirmOrderMobile,
      findOrderSummary,
    ])('when %s emits an `error` event', (findMethod) => {
      beforeEach(() => {
        createComponent();
        findMethod().vm.$emit(PurchaseEvent.ERROR, error);
        return nextTick();
      });

      it('passes the correct props', () => {
        expect(findErrorAlert().props('error')).toBe(error);
      });

      it('captures the error', () => {
        expect(Sentry.captureException.mock.calls[0][0]).toBe(error);
      });
    });

    describe.each([findCheckout, findOrderSummary])(
      'when %s emits an `error-reset` event',
      (findMethod) => {
        beforeEach(() => {
          createComponent();
          findMethod().vm.$emit(PurchaseEvent.ERROR, error);
          return nextTick();
        });

        it('does not the alert', async () => {
          findMethod().vm.$emit(PurchaseEvent.ERROR_RESET);

          await nextTick();

          expect(findErrorAlert().exists()).toBe(false);
        });
      },
    );
  });
});
