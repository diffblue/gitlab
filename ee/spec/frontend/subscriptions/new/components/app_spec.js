import { nextTick } from 'vue';
import { GlAlert } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import Component from 'ee/subscriptions/new/components/app.vue';
import OrderSummary from 'ee/subscriptions/new/components/order_summary.vue';
import Checkout from 'ee/subscriptions/new/components/checkout.vue';
import Modal from 'ee/subscriptions/new/components/modal.vue';
import { stubExperiments } from 'helpers/experimentation_helper';
import GitlabExperiment from '~/experimentation/components/gitlab_experiment.vue';

describe('App component', () => {
  let wrapper;

  const createComponent = () => {
    return shallowMountExtended(Component, {
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

  const findModalComponent = () => wrapper.findComponent(Modal);
  const findOrderSummaryComponent = () => wrapper.findComponent(OrderSummary);
  const findAlertComponent = () => wrapper.findComponent(GlAlert);

  describe('cart_abandonment_modal experiment', () => {
    describe('control', () => {
      beforeEach(() => {
        stubExperiments({ cart_abandonment_modal: 'control' });
        wrapper = createComponent();
      });

      it('matches the snapshot', () => {
        expect(wrapper.element).toMatchSnapshot();
      });

      it('renders the modal', () => {
        expect(findModalComponent().exists()).toBe(false);
      });
    });

    describe('candidate', () => {
      beforeEach(() => {
        stubExperiments({ cart_abandonment_modal: 'candidate' });
        wrapper = createComponent();
      });

      it('matches the snapshot', () => {
        expect(wrapper.element).toMatchSnapshot();
      });

      it('renders the modal', () => {
        expect(findModalComponent().exists()).toBe(true);
      });
    });
  });

  describe('step order app', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('renders checkout', () => {
      expect(wrapper.findComponent(Checkout).exists()).toBe(true);
    });

    it('renders order summary', () => {
      expect(findOrderSummaryComponent().exists()).toBe(true);
    });

    it('renders alert message when present', async () => {
      const errorMessage = `Hello! I'm Error.`;

      findOrderSummaryComponent().vm.$emit('error', errorMessage);
      await nextTick();

      expect(findAlertComponent().text()).toBe(errorMessage);
    });

    it('does not render alert message when not present', async () => {
      findOrderSummaryComponent().vm.$emit('error', null);
      await nextTick();

      expect(findAlertComponent().exists()).toBe(false);
    });
  });

  describe('confirm order CTA', () => {
    it(`should show confirm order CTA`, async () => {
      wrapper = createComponent();
      await nextTick();

      expect(wrapper.findByTestId('confirm-order-desktop').classes()).toEqual([
        'gl-display-none',
        'gl-lg-display-block!',
      ]);
      expect(wrapper.findByTestId('confirm-order-mobile').classes()).toEqual([
        'gl-display-block',
        'gl-lg-display-none!',
      ]);
    });
  });
});
