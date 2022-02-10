<script>
import StepOrderApp from 'ee/vue_shared/purchase_flow/components/step_order_app.vue';
import GitlabExperiment from '~/experimentation/components/gitlab_experiment.vue';
import Modal from './modal.vue';
import Checkout from './checkout.vue';
import OrderSummary from './order_summary.vue';

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
  <div class="gl-h-full">
    <gitlab-experiment name="cart_abandonment_modal">
      <template #candidate>
        <modal />
      </template>
    </gitlab-experiment>

    <step-order-app class="gl-h-full">
      <template #checkout>
        <checkout />
      </template>
      <template #order-summary>
        <order-summary />
      </template>
    </step-order-app>
  </div>
</template>
