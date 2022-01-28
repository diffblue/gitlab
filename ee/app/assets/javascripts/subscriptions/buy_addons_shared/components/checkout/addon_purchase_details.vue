<script>
import { GlAlert, GlFormInput } from '@gitlab/ui';
import { STEPS } from 'ee/subscriptions/constants';
import updateState from 'ee/subscriptions/graphql/mutations/update_state.mutation.graphql';
import Step from 'ee/vue_shared/purchase_flow/components/step.vue';
import { GENERAL_ERROR_MESSAGE } from 'ee/vue_shared/purchase_flow/constants';
import createFlash from '~/flash';
import autofocusonshow from '~/vue_shared/directives/autofocusonshow';
import {
  I18N_DETAILS_STEP_TITLE,
  I18N_DETAILS_NEXT_STEP_BUTTON_TEXT,
  I18N_DETAILS_INVALID_QUANTITY_MESSAGE,
} from '../../constants';

export default {
  name: 'AddonPurchaseDetails',
  components: {
    GlAlert,
    GlFormInput,
    Step,
  },
  directives: {
    autofocusonshow,
  },
  props: {
    productLabel: {
      type: String,
      required: true,
    },
    quantity: {
      type: Number,
      required: true,
    },
    showAlert: {
      type: Boolean,
      required: false,
    },
    alertText: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    quantityModel: {
      get() {
        return this.quantity || 0;
      },
      set(quantity) {
        this.updateQuantity(quantity || 0);
      },
    },
    isValid() {
      return this.quantity > 0;
    },
  },
  methods: {
    updateQuantity(quantity = 0) {
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
    stepTitle: I18N_DETAILS_STEP_TITLE,
    nextStepButtonText: I18N_DETAILS_NEXT_STEP_BUTTON_TEXT,
    invalidQuantityErrorMessage: I18N_DETAILS_INVALID_QUANTITY_MESSAGE,
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
    :error-message="$options.i18n.invalidQuantityErrorMessage"
    :next-step-button-text="$options.i18n.nextStepButtonText"
  >
    <template #body>
      <gl-alert v-if="showAlert && alertText" variant="info" class="gl-mb-3" :dismissible="false">
        {{ alertText }}
      </gl-alert>
      <label class="gl-mt-3" for="quantity" data-testid="product-label">
        {{ productLabel }}
      </label>
      <div
        :class="[
          { 'gl-mb-6': isValid },
          'gl-display-flex gl-flex-direction-row gl-align-items-center',
        ]"
      >
        <gl-form-input
          ref="quantity"
          v-model.number="quantityModel"
          name="quantity"
          type="number"
          :min="1"
          :state="isValid"
          data-qa-selector="quantity"
          class="gl-w-15"
        />
        <div class="gl-ml-3" data-testid="addon-quantity-text">
          <slot name="formula"></slot>
        </div>
      </div>
    </template>
    <template #summary>
      <slot name="summary-label"></slot>
    </template>
  </step>
</template>
