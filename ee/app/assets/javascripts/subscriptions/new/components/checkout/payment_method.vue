<script>
import { GlSprintf } from '@gitlab/ui';
import { mapState } from 'vuex';
import { STEP_PAYMENT_METHOD, TRACK_SUCCESS_MESSAGE } from 'ee/subscriptions/constants';
import Step from 'ee/vue_shared/purchase_flow/components/step.vue';
import { sprintf, s__ } from '~/locale';
import Tracking from '~/tracking';
import Zuora from './zuora.vue';

export default {
  components: {
    GlSprintf,
    Step,
    Zuora,
  },
  mixins: [Tracking.mixin()],
  computed: {
    ...mapState(['paymentMethodId', 'creditCardDetails']),
    isValid() {
      return Boolean(this.paymentMethodId);
    },
    expirationDate() {
      return sprintf(this.$options.i18n.expirationDate, {
        expirationMonth: this.creditCardDetails.credit_card_expiration_month,
        expirationYear: this.creditCardDetails.credit_card_expiration_year.toString(10).slice(-2),
      });
    },
  },
  methods: {
    trackStepSuccess() {
      this.track('click_button', {
        label: 'review_order',
        property: TRACK_SUCCESS_MESSAGE,
      });
    },
    trackStepError(errorMessage) {
      this.track('click_button', {
        label: 'review_order',
        property: errorMessage,
      });
    },
    trackStepEdit() {
      this.track('click_button', {
        label: 'edit',
        property: STEP_PAYMENT_METHOD,
      });
    },
  },
  i18n: {
    stepTitle: s__('Checkout|Payment method'),
    creditCardDetails: s__('Checkout|%{cardType} ending in %{lastFourDigits}'),
    expirationDate: s__('Checkout|Exp %{expirationMonth}/%{expirationYear}'),
  },
  stepId: STEP_PAYMENT_METHOD,
};
</script>
<template>
  <step
    :step-id="$options.stepId"
    :title="$options.i18n.stepTitle"
    :is-valid="isValid"
    @stepEdit="trackStepEdit"
  >
    <template #body="props">
      <zuora :active="props.active" @success="trackStepSuccess" @error="trackStepError" />
    </template>
    <template #summary>
      <div class="js-summary-line-1">
        <gl-sprintf :message="$options.i18n.creditCardDetails">
          <template #cardType>
            {{ creditCardDetails.credit_card_type }}
          </template>
          <template #lastFourDigits>
            <strong>{{ creditCardDetails.credit_card_mask_number.slice(-4) }}</strong>
          </template>
        </gl-sprintf>
      </div>
      <div class="js-summary-line-2">
        {{ expirationDate }}
      </div>
    </template>
  </step>
</template>
