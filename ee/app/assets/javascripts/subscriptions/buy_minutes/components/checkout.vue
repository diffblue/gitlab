<script>
import { s__ } from '~/locale';
import AddonPurchaseDetails from './checkout/addon_purchase_details.vue';
import BillingAddress from './checkout/billing_address.vue';
import ConfirmOrder from './checkout/confirm_order.vue';
import PaymentMethod from './checkout/payment_method.vue';

export default {
  components: { AddonPurchaseDetails, BillingAddress, PaymentMethod, ConfirmOrder },
  props: {
    plan: {
      type: Object,
      required: true,
    },
  },
  i18n: {
    checkout: s__('Checkout|Checkout'),
  },
};
</script>
<template>
  <div class="checkout gl-display-flex gl-flex-direction-column gl-align-items-center">
    <div class="flash-container"></div>
    <h2 class="gl-mt-6 gl-mb-7 gl-mb-lg-5">{{ $options.i18n.checkout }}</h2>
    <addon-purchase-details :plan="plan" />
    <billing-address />
    <payment-method />
    <confirm-order />
  </div>
</template>
