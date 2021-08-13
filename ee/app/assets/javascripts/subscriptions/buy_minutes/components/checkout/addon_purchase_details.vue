<script>
import { GlAlert, GlFormInput, GlSprintf } from '@gitlab/ui';
import { CI_MINUTES_PER_PACK } from 'ee/subscriptions/buy_minutes/constants';
import { STEPS } from 'ee/subscriptions/constants';
import updateState from 'ee/subscriptions/graphql/mutations/update_state.mutation.graphql';
import stateQuery from 'ee/subscriptions/graphql/queries/state.query.graphql';
import Step from 'ee/vue_shared/purchase_flow/components/step.vue';
import { GENERAL_ERROR_MESSAGE } from 'ee/vue_shared/purchase_flow/constants';
import createFlash from '~/flash';
import { n__, s__, sprintf, formatNumber } from '~/locale';
import autofocusonshow from '~/vue_shared/directives/autofocusonshow';

export default {
  name: 'AddonPurchaseDetails',
  components: {
    GlAlert,
    GlFormInput,
    GlSprintf,
    Step,
  },
  directives: {
    autofocusonshow,
  },
  apollo: {
    quantity: {
      query: stateQuery,
      update(data) {
        return data.subscription.quantity;
      },
    },
  },
  computed: {
    quantityModel: {
      get() {
        return this.quantity || 1;
      },
      set(quantity) {
        this.updateQuantity(quantity);
      },
    },
    isValid() {
      return this.quantity > 0;
    },
    totalCiMinutes() {
      return this.quantity * CI_MINUTES_PER_PACK;
    },
    summaryCiMinutesQuantityText() {
      return n__('Checkout|%d CI minute pack', 'Checkout|%d CI minute packs', this.quantity);
    },
    ciMinutesQuantityText() {
      return sprintf(
        n__(
          'Checkout|%{totalCiMinutes} CI minute',
          'Checkout|%{totalCiMinutes} CI minutes',
          this.totalCiMinutes,
        ),
        { totalCiMinutes: formatNumber(this.totalCiMinutes) },
      );
    },
    summaryCiMinutesTotal() {
      return sprintf(this.$options.i18n.summaryCiMinutesTotal, {
        quantity: formatNumber(this.totalCiMinutes),
      });
    },
  },
  methods: {
    updateQuantity(quantity = 1) {
      this.$apollo
        .mutate({
          mutation: updateState,
          variables: {
            input: { subscription: { quantity } },
          },
        })
        .catch((error) => {
          createFlash({ message: GENERAL_ERROR_MESSAGE, error, captureError: true });
        });
    },
  },
  i18n: {
    stepTitle: s__('Checkout|Purchase details'),
    nextStepButtonText: s__('Checkout|Continue to billing'),
    ciMinutesLabel: s__('Checkout|CI minute pack'),
    ciMinutesAlertText: s__(
      "Checkout|CI minute packs are only used after you've used your subscription's monthly quota. The additional minutes will roll over month to month and are valid for one year.",
    ),
    ciMinutesPacksQuantityFormula: s__('Checkout|x 1,000 minutes per pack = %{strong}'),
    ciMinutesQuantityText: s__('Checkout|%{totalCiMinutes} CI minutes'),
    summaryCiMinutesTotal: s__('Checkout|Total minutes: %{quantity}'),
  },
  stepId: STEPS[0].id,
};
</script>
<template>
  <step
    v-if="!$apollo.loading"
    :step-id="$options.stepId"
    :title="$options.i18n.stepTitle"
    :is-valid="isValid"
    :next-step-button-text="$options.i18n.nextStepButtonText"
  >
    <template #body>
      <gl-alert variant="info" class="gl-mb-3" :dismissible="false">
        {{ $options.i18n.ciMinutesAlertText }}
      </gl-alert>
      <label class="gl-mt-3" for="quantity" data-testid="product-label">
        {{ $options.i18n.ciMinutesLabel }}
      </label>
      <div class="gl-display-flex gl-flex-direction-row gl-align-items-center gl-mb-6">
        <gl-form-input
          ref="quantity"
          v-model.number="quantityModel"
          name="quantity"
          type="number"
          :min="1"
          data-qa-selector="quantity"
          class="gl-w-15"
        />
        <div class="gl-ml-3" data-testid="ci-minutes-quantity-text">
          <gl-sprintf :message="$options.i18n.ciMinutesPacksQuantityFormula">
            <template #strong>
              <strong>{{ ciMinutesQuantityText }}</strong>
            </template>
          </gl-sprintf>
        </div>
      </div>
    </template>
    <template #summary>
      <strong ref="summary-line-1">
        {{ summaryCiMinutesQuantityText }}
      </strong>
      <div ref="summary-line-3">{{ summaryCiMinutesTotal }}</div>
    </template>
  </step>
</template>
