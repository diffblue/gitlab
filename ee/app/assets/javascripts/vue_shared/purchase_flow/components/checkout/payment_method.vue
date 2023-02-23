<script>
import { GlSprintf } from '@gitlab/ui';
import find from 'lodash/find';
import { STEPS } from 'ee/subscriptions/constants';
import stateQuery from 'ee/subscriptions/graphql/queries/state.query.graphql';
import Step from 'ee/vue_shared/purchase_flow/components/step.vue';
import Zuora from 'ee/vue_shared/purchase_flow/components/checkout/zuora.vue';
import { s__, sprintf } from '~/locale';
import { PurchaseEvent } from 'ee/subscriptions/new/constants';

export default {
  components: {
    GlSprintf,
    Step,
    Zuora,
  },
  apollo: {
    paymentMethod: {
      query: stateQuery,
      update: (data) => data.paymentMethod,
    },
    selectedNamespace: {
      query: stateQuery,
      update: ({ eligibleNamespaces, selectedNamespaceId }) => {
        const id = Number(selectedNamespaceId);
        return find(eligibleNamespaces, { id });
      },
    },
  },
  computed: {
    accountId() {
      return this.selectedNamespace?.accountId || '';
    },
    isValid() {
      return Boolean(this.paymentMethod.id);
    },
    expirationDate() {
      return sprintf(this.$options.i18n.expirationDate, {
        expirationMonth: this.paymentMethod.creditCardExpirationMonth,
        expirationYear: this.paymentMethod.creditCardExpirationYear.toString(10).slice(-2),
      });
    },
  },
  methods: {
    handleError(payload) {
      this.$emit(PurchaseEvent.ERROR, payload);
    },
  },
  i18n: {
    stepTitle: s__('Checkout|Payment method'),
    paymentMethod: s__('Checkout|%{cardType} ending in %{lastFourDigits}'),
    expirationDate: s__('Checkout|Exp %{expirationMonth}/%{expirationYear}'),
  },
  stepId: STEPS[2].id,
};
</script>
<template>
  <step :step-id="$options.stepId" :title="$options.i18n.stepTitle" :is-valid="isValid">
    <template #body="{ active }">
      <zuora :active="active" :account-id="accountId" @error="handleError" />
    </template>
    <template #summary>
      <div data-testid="card-details">
        <gl-sprintf :message="$options.i18n.paymentMethod">
          <template #cardType>
            {{ paymentMethod.creditCardType }}
          </template>
          <template #lastFourDigits>
            <strong>{{ paymentMethod.creditCardMaskNumber.slice(-4) }}</strong>
          </template>
        </gl-sprintf>
      </div>
      <div data-testid="card-expiration">
        {{ expirationDate }}
      </div>
    </template>
  </step>
</template>
