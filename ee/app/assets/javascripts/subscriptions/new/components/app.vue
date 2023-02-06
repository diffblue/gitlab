<script>
import StepOrderApp from 'ee/vue_shared/purchase_flow/components/step_order_app.vue';
import GitlabExperiment from '~/experimentation/components/gitlab_experiment.vue';
import Checkout from 'jh_else_ee/subscriptions/new/components/checkout.vue';
import ConfirmOrder from 'ee/subscriptions/new/components/checkout/confirm_order.vue';
import OrderSummary from 'jh_else_ee/subscriptions/new/components/order_summary.vue';
import Modal from 'ee/subscriptions/new/components/modal.vue';
import { GENERAL_ERROR_MESSAGE } from 'ee/vue_shared/purchase_flow/constants';
import { createAlert } from '~/flash';

export default {
  components: {
    StepOrderApp,
    GitlabExperiment,
    Modal,
    Checkout,
    OrderSummary,
    ConfirmOrder,
  },
  methods: {
    showError({ error, message = GENERAL_ERROR_MESSAGE }) {
      createAlert({ message, error, captureError: true });
    },
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
          @error="showError"
        />
      </template>
      <template #order-summary>
        <order-summary />
        <confirm-order
          class="gl-display-block gl-lg-display-none!"
          data-testid="confirm-order-mobile"
          @error="showError"
        />
      </template>
    </step-order-app>
  </div>
</template>
