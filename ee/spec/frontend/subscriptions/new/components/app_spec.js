import { nextTick } from 'vue';
import * as Sentry from '@sentry/browser';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import Component from 'ee/subscriptions/new/components/app.vue';
import OrderSummary from 'ee/subscriptions/new/components/order_summary.vue';
import Checkout from 'ee/subscriptions/new/components/checkout.vue';
import Modal from 'ee/subscriptions/new/components/modal.vue';
import { stubExperiments } from 'helpers/experimentation_helper';
import GitlabExperiment from '~/experimentation/components/gitlab_experiment.vue';
import { PurchaseEvent } from 'ee/subscriptions/new/constants';
import ErrorAlert from 'ee/vue_shared/purchase_flow/components/checkout/error_alert.vue';

describe('App component', () => {
  let wrapper;

  const findModalComponent = () => wrapper.findComponent(Modal);
  const findCheckout = () => wrapper.findComponent(Checkout);
  const findConfirmOrderDesktop = () => wrapper.findByTestId('confirm-order-desktop');
  const findConfirmOrderMobile = () => wrapper.findByTestId('confirm-order-mobile');
  const findErrorAlert = () => wrapper.findComponent(ErrorAlert);
  const findOrderSummary = () => wrapper.findComponent(OrderSummary);

  const createComponent = () => {
    wrapper = shallowMountExtended(Component, {
      stubs: {
        Modal,
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

  describe('cart_abandonment_modal experiment', () => {
    describe('control', () => {
      beforeEach(() => {
        stubExperiments({ cart_abandonment_modal: 'control' });
        createComponent();
      });

      it('renders the modal', () => {
        expect(findModalComponent().exists()).toBe(false);
      });
    });

    describe('candidate', () => {
      beforeEach(() => {
        stubExperiments({ cart_abandonment_modal: 'candidate' });
        createComponent();
      });

      it('renders the modal', () => {
        expect(findModalComponent().exists()).toBe(true);
      });
    });
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

  describe('when the children component emit events', () => {
    const error = new Error('Yikes!');

    describe.each([findConfirmOrderDesktop, findConfirmOrderDesktop, findConfirmOrderMobile])(
      'when %s emits an `error` event',
      (findMethod) => {
        beforeEach(() => {
          createComponent();
          findMethod().vm.$emit(PurchaseEvent.ERROR, error);
          return nextTick();
        });

        it('shows the alert', () => {
          expect(findErrorAlert().exists()).toBe(true);
        });

        it('passes the correct props', () => {
          expect(findErrorAlert().props('error')).toBe(error);
        });

        it('captures the error', () => {
          expect(Sentry.captureException.mock.calls[0][0]).toBe(error);
        });
      },
    );

    describe('when emitting an `error-reset` event', () => {
      beforeEach(() => {
        createComponent();
        findCheckout().vm.$emit(PurchaseEvent.ERROR, error);
        return nextTick();
      });

      it('shows the alert', async () => {
        findCheckout().vm.$emit(PurchaseEvent.ERROR_RESET);

        await nextTick();

        expect(findErrorAlert().exists()).toBe(false);
      });
    });
  });
});
