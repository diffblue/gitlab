<script>
import * as Sentry from '@sentry/browser';
import StepOrderApp from 'ee/vue_shared/purchase_flow/components/step_order_app.vue';
import Checkout from 'jh_else_ee/subscriptions/new/components/checkout.vue';
import ConfirmOrder from 'ee/subscriptions/new/components/checkout/confirm_order.vue';
import OrderSummary from 'jh_else_ee/subscriptions/new/components/order_summary.vue';
import ErrorAlert from 'ee/vue_shared/purchase_flow/components/checkout/error_alert.vue';

export default {
  components: {
    StepOrderApp,
    Checkout,
    OrderSummary,
    ConfirmOrder,
    ErrorAlert,
  },
  data() {
    return {
      error: null,
    };
  },
  mounted() {
    this.$store.subscribeAction({
      after: this.handleVuexActionDispatch,
    });
  },
  methods: {
    handleError(error) {
      this.error = error;
      Sentry.captureException(error);
    },
    handleVuexActionDispatch(action) {
      if (action.type === 'confirmOrderError') {
        this.handleError(action.payload);
      }
    },
    hideError() {
      this.error = null;
    },
  },
};
</script>
<template>
  <div>
    <error-alert v-if="error" class="gl-mb-4" :error="error" />
    <step-order-app>
      <template #checkout>
        <checkout @error="handleError" @error-reset="hideError" />
        <confirm-order
          class="gl-display-none gl-lg-display-block!"
          data-testid="confirm-order-desktop"
          @error="handleError"
        />
      </template>
      <template #order-summary>
        <order-summary @error="handleError" @error-reset="hideError" />
        <confirm-order
          class="gl-display-block gl-lg-display-none!"
          data-testid="confirm-order-mobile"
          @error="handleError"
        />
      </template>
    </step-order-app>
  </div>
</template>
