<script>
import { GlSprintf } from '@gitlab/ui';
import { STEPS } from 'ee/subscriptions/constants';
import stateQuery from 'ee/subscriptions/graphql/queries/state.query.graphql';
import Step from 'ee/vue_shared/purchase_flow/components/step.vue';
import { sprintf, s__ } from '~/locale';
import Zuora from './zuora.vue';

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
  },
  computed: {
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
      <zuora :active="active" />
    </template>
    <template #summary>
      <div class="js-summary-line-1">
        <gl-sprintf :message="$options.i18n.paymentMethod">
          <template #cardType>
            {{ paymentMethod.creditCardType }}
          </template>
          <template #lastFourDigits>
            <strong>{{ paymentMethod.creditCardMaskNumber.slice(-4) }}</strong>
          </template>
        </gl-sprintf>
      </div>
      <div class="js-summary-line-2">
        {{ expirationDate }}
      </div>
    </template>
  </step>
</template>
