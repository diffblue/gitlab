<script>
import updateState from 'ee/subscriptions/graphql/mutations/update_state.mutation.graphql';
import BillingAddress from 'jh_else_ee/vue_shared/purchase_flow/components/checkout/billing_address.vue';
import ConfirmOrder from 'ee/vue_shared/purchase_flow/components/checkout/confirm_order.vue';
import PaymentMethod from 'ee/vue_shared/purchase_flow/components/checkout/payment_method.vue';
import { GENERAL_ERROR_MESSAGE } from 'ee/vue_shared/purchase_flow/constants';
import createFlash from '~/flash';
import { s__ } from '~/locale';

export default {
  components: {
    BillingAddress,
    PaymentMethod,
    ConfirmOrder,
  },
  props: {
    plan: {
      type: Object,
      required: true,
    },
  },
  mounted() {
    this.updateSelectedPlan(this.plan);
  },
  methods: {
    updateSelectedPlan({ id, isAddon } = {}) {
      this.$apollo
        .mutate({
          mutation: updateState,
          variables: {
            input: { selectedPlan: { id, isAddon } },
          },
        })
        .catch((error) => {
          createFlash({ message: GENERAL_ERROR_MESSAGE, error, captureError: true });
        });
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
    <h2 class="gl-align-self-start gl-mt-6 gl-mb-7 gl-mb-lg-5">{{ $options.i18n.checkout }}</h2>
    <slot name="purchase-details"></slot>
    <billing-address />
    <payment-method />
    <confirm-order />
  </div>
</template>
