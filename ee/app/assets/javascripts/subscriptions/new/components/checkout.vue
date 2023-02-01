<script>
import Tracking from '~/tracking';
import BillingAddress from 'ee/subscriptions/new/components/checkout/billing_address.vue';
import ConfirmOrder from 'ee/subscriptions/new/components/checkout/confirm_order.vue';
import PaymentMethod from 'ee/subscriptions/new/components/checkout/payment_method.vue';
import SubscriptionDetails from 'ee/subscriptions/new/components/checkout/subscription_details.vue';
import { GENERAL_ERROR_MESSAGE } from 'ee/vue_shared/purchase_flow/constants';
import { createAlert } from '~/flash';

export default {
  components: { BillingAddress, ConfirmOrder, PaymentMethod, SubscriptionDetails },
  mixins: [Tracking.mixin()],
  data() {
    return {
      errorAlert: {},
    };
  },
  mounted() {
    this.track('render', { label: 'saas_checkout' });
  },
  methods: {
    hideError() {
      this.errorAlert?.dismiss();
    },
    showError({ error, message = GENERAL_ERROR_MESSAGE }) {
      this.errorAlert = createAlert({ message, error, captureError: true });
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
    <confirm-order @error="showError" />
  </div>
</template>
