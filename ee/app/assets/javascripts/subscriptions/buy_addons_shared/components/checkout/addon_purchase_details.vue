<script>
import { GlAlert, GlFormInput } from '@gitlab/ui';
import { STEPS } from 'ee/subscriptions/constants';
import updateState from 'ee/subscriptions/graphql/mutations/update_state.mutation.graphql';
import Step from 'ee/vue_shared/purchase_flow/components/step.vue';
import autofocusonshow from '~/vue_shared/directives/autofocusonshow';
import { PurchaseEvent } from 'ee/subscriptions/new/constants';
import {
  I18N_DETAILS_STEP_TITLE,
  I18N_DETAILS_NEXT_STEP_BUTTON_TEXT,
  I18N_DETAILS_INVALID_QUANTITY_MESSAGE,
} from '../../constants';

const DEFAULT_MIN_QUANTITY = 1;

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
  data() {
    return {
      quantityModel: this.quantity || DEFAULT_MIN_QUANTITY,
    };
  },
  computed: {
    isValid() {
      return this.quantityModel >= DEFAULT_MIN_QUANTITY && Number.isInteger(this.quantityModel);
    },
  },
  watch: {
    quantityModel(value) {
      this.updateQuantity(value);
    },
  },
  methods: {
    updateQuantity() {
      if (!this.isValid) {
        return;
      }

      this.$apollo
        .mutate({
          mutation: updateState,
          variables: {
            input: { subscription: { quantity: this.quantityModel } },
          },
        })
        .catch(this.handleError);
    },
    handleError(error) {
      this.$emit(PurchaseEvent.ERROR, error);
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
      <label for="quantity" data-testid="product-label">
        {{ productLabel }}
      </label>
      <div
        :class="[
          { 'gl-mb-5': isValid },
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
