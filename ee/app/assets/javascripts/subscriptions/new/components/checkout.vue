<script>
import Tracking from '~/tracking';
import BillingAddress from './checkout/billing_address.vue';
import PaymentMethod from './checkout/payment_method.vue';
import SubscriptionDetails from './checkout/subscription_details.vue';

export default {
  components: { SubscriptionDetails, BillingAddress, PaymentMethod },
  mixins: [Tracking.mixin()],
  mounted() {
    this.track('render', { label: 'saas_checkout' });
  },
};
</script>
<template>
  <div>
    <div class="flash-container"></div>
    <subscription-details />
    <billing-address />
    <payment-method />
  </div>
</template>
