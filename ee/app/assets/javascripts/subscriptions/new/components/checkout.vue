<script>
import Tracking from '~/tracking';
import BillingAddress from 'ee/subscriptions/new/components/checkout/billing_address.vue';
import PaymentMethod from 'ee/subscriptions/new/components/checkout/payment_method.vue';
import SubscriptionDetails from 'ee/subscriptions/new/components/checkout/subscription_details.vue';
import { PurchaseEvent } from 'ee/subscriptions/new/constants';

export default {
  components: { BillingAddress, PaymentMethod, SubscriptionDetails },
  mixins: [Tracking.mixin()],
  mounted() {
    this.track('render', { label: 'saas_checkout' });
  },
  methods: {
    hideError() {
      this.$emit(PurchaseEvent.ERROR_RESET);
    },
    showError(error) {
      this.$emit(PurchaseEvent.ERROR, error);
    },
  },
};
</script>
<template>
  <div>
    <div class="flash-container"></div>
    <subscription-details @error="showError" @error-reset="hideError" />
    <billing-address />
    <payment-method />
  </div>
</template>
