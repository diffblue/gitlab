import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import Component from 'ee/subscriptions/new/components/app.vue';
import OrderSummary from 'ee/subscriptions/new/components/order_summary.vue';
import Checkout from 'ee/subscriptions/new/components/checkout.vue';
import Modal from 'ee/subscriptions/new/components/modal.vue';
import { stubExperiments } from 'helpers/experimentation_helper';
import GitlabExperiment from '~/experimentation/components/gitlab_experiment.vue';
import { createAlert } from '~/flash';
import { GENERAL_ERROR_MESSAGE } from 'ee/vue_shared/purchase_flow/constants';
import { PurchaseEvent } from 'ee/subscriptions/new/constants';

jest.mock('~/flash');

describe('App component', () => {
  let wrapper;

  const findConfirmOrderDesktop = () => wrapper.findByTestId('confirm-order-desktop');
  const findConfirmOrderMobile = () => wrapper.findByTestId('confirm-order-mobile');

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

  describe('cart_abandonment_modal experiment', () => {
    describe('control', () => {
      beforeEach(() => {
        stubExperiments({ cart_abandonment_modal: 'control' });
        createComponent();
      });

      it('matches the snapshot', () => {
        expect(wrapper.element).toMatchSnapshot();
      });

      it('renders the modal', () => {
        expect(wrapper.findComponent(Modal).exists()).toBe(false);
      });
    });

    describe('candidate', () => {
      beforeEach(() => {
        stubExperiments({ cart_abandonment_modal: 'candidate' });
        createComponent();
      });

      it('matches the snapshot', () => {
        expect(wrapper.element).toMatchSnapshot();
      });

      it('renders the modal', () => {
        expect(wrapper.findComponent(Modal).exists()).toBe(true);
      });
    });
  });

  describe('step order app', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders checkout', () => {
      expect(wrapper.findComponent(Checkout).exists()).toBe(true);
    });

    it('renders order summary', () => {
      expect(wrapper.findComponent(OrderSummary).exists()).toBe(true);
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

    beforeEach(() => {
      createComponent();
    });

    it('creates an alert from confirm order desktop', () => {
      findConfirmOrderDesktop().vm.$emit(PurchaseEvent.ERROR, { error });

      expect(createAlert).toHaveBeenCalledWith({
        message: GENERAL_ERROR_MESSAGE,
        captureError: true,
        error,
      });
    });

    it('creates an alert from confirm order mobile', () => {
      findConfirmOrderMobile().vm.$emit(PurchaseEvent.ERROR, { error });

      expect(createAlert).toHaveBeenCalledWith({
        message: GENERAL_ERROR_MESSAGE,
        captureError: true,
        error,
      });
    });
  });
});
