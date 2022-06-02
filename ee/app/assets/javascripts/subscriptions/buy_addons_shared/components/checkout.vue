<script>
import { logError } from '~/lib/logger';
import updateState from 'ee/subscriptions/graphql/mutations/update_state.mutation.graphql';
import BillingAddress from 'jh_else_ee/vue_shared/purchase_flow/components/checkout/billing_address.vue';
import ConfirmOrder from 'ee/vue_shared/purchase_flow/components/checkout/confirm_order.vue';
import PaymentMethod from 'ee/vue_shared/purchase_flow/components/checkout/payment_method.vue';
import { GENERAL_ERROR_MESSAGE } from 'ee/vue_shared/purchase_flow/constants';
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
          this.emitError(error);
        });
    },
    emitError(error) {
      this.$emit('alertError', GENERAL_ERROR_MESSAGE);
      logError(error);
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
    <billing-address />
    <payment-method />
    <confirm-order />
  </div>
</template>
