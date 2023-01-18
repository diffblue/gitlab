<script>
import StepOrderApp from 'ee/vue_shared/purchase_flow/components/step_order_app.vue';
import GitlabExperiment from '~/experimentation/components/gitlab_experiment.vue';
import Checkout from 'jh_else_ee/subscriptions/new/components/checkout.vue';
import OrderSummary from 'jh_else_ee/subscriptions/new/components/order_summary.vue';
import Modal from './modal.vue';
import ConfirmOrder from './checkout/confirm_order.vue';

export default {
  components: {
    StepOrderApp,
    GitlabExperiment,
    Modal,
    Checkout,
    OrderSummary,
    ConfirmOrder,
  },
};
</script>
<template>
  <div>
    <gitlab-experiment name="cart_abandonment_modal">
      <template #candidate>
        <modal />
      </template>
    </gitlab-experiment>

    <step-order-app>
      <template #checkout>
        <checkout />
        <confirm-order
          class="gl-display-none gl-lg-display-block!"
          data-testid="confirm-order-desktop"
        />
      </template>
      <template #order-summary>
        <order-summary />
        <confirm-order
          class="gl-display-block gl-lg-display-none!"
          data-testid="confirm-order-mobile"
        />
      </template>
    </step-order-app>
  </div>
</template>
