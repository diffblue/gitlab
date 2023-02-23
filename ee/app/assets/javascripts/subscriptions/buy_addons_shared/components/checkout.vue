<script>
import updateState from 'ee/subscriptions/graphql/mutations/update_state.mutation.graphql';
import BillingAddress from 'jh_else_ee/vue_shared/purchase_flow/components/checkout/billing_address.vue';
import ConfirmOrder from 'ee/vue_shared/purchase_flow/components/checkout/confirm_order.vue';
import PaymentMethod from 'ee/vue_shared/purchase_flow/components/checkout/payment_method.vue';
import { s__ } from '~/locale';
import { PurchaseEvent } from 'ee/subscriptions/new/constants';

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
      return this.$apollo
        .mutate({
          mutation: updateState,
          variables: {
            input: { selectedPlan: { id, isAddon } },
          },
        })
        .catch(this.handleError);
    },
    handleError(error) {
      this.$emit(PurchaseEvent.ERROR, error);
    },
  },
  i18n: {
    checkout: s__('Checkout|Checkout'),
  },
};
</script>
<template>
  <div>
    <div class="flash-container"></div>
    <slot name="purchase-details"></slot>
    <billing-address @error="handleError" />
    <payment-method @error="handleError" />
    <confirm-order @error="handleError" />
  </div>
</template>
