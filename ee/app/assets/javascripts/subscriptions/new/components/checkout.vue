<script>
import { mapState } from 'vuex';
import ProgressBar from 'ee/registrations/components/progress_bar.vue';
import { STEPS, SUBSCRIPTON_FLOW_STEPS } from 'ee/registrations/constants';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import BillingAddress from 'jh_else_ee/subscriptions/new/components/checkout/billing_address.vue';
import ConfirmOrder from './checkout/confirm_order.vue';
import PaymentMethod from './checkout/payment_method.vue';
import SubscriptionDetails from './checkout/subscription_details.vue';

export default {
  components: { ProgressBar, SubscriptionDetails, BillingAddress, PaymentMethod, ConfirmOrder },
  mixins: [Tracking.mixin()],
  currentStep: STEPS.checkout,
  steps: SUBSCRIPTON_FLOW_STEPS,
  computed: {
    ...mapState(['isNewUser']),
  },
  mounted() {
    this.track('render', { label: 'saas_checkout' });
  },
  i18n: {
    checkout: s__('Checkout|Checkout'),
  },
};
</script>
<template>
  <div class="checkout d-flex flex-column justify-content-between w-100">
    <div class="full-width">
      <progress-bar v-if="isNewUser" :steps="$options.steps" :current-step="$options.currentStep" />
      <div class="flash-container"></div>
      <h2 class="mt-4 mb-3 mb-lg-5">{{ $options.i18n.checkout }}</h2>
      <subscription-details />
      <billing-address />
      <payment-method />
    </div>
    <confirm-order />
  </div>
</template>
