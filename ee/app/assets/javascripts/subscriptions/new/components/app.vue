<script>
import StepOrderApp from 'ee/vue_shared/purchase_flow/components/step_order_app.vue';
import GitlabExperiment from '~/experimentation/components/gitlab_experiment.vue';
import Checkout from 'jh_else_ee/subscriptions/new/components/checkout.vue';
import OrderSummary from 'jh_else_ee/subscriptions/new/components/order_summary.vue';
import Modal from './modal.vue';

export default {
  components: {
    StepOrderApp,
    GitlabExperiment,
    Modal,
    Checkout,
    OrderSummary,
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
      </template>
      <template #order-summary>
        <order-summary />
      </template>
    </step-order-app>
  </div>
</template>
