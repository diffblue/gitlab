<script>
import { GlButton, GlFormGroup, GlFormInputGroup, GlFormInput, GlAlert } from '@gitlab/ui';
import isEmpty from 'lodash/isEmpty';
import { s__, __ } from '~/locale';

const i18n = Object.freeze({
  label: s__('Checkout|Coupon code (optional)'),
  applyButtonText: __('Apply'),
});

export default {
  name: 'PromoCodeInput',
  components: { GlButton, GlFormGroup, GlFormInputGroup, GlFormInput, GlAlert },
  props: {
    canShowSuccessAlert: {
      type: Boolean,
      required: false,
      default: false,
    },
    applyingPromoCode: {
      type: Boolean,
      required: false,
      default: false,
    },
    successMessage: {
      type: String,
      required: false,
      default: '',
    },
    errorMessage: {
      type: String,
      required: false,
      default: '',
    },
  },
  i18n,
  data() {
    return {
      promoCode: '',
    };
  },
  computed: {
    promoCodeSuccessful() {
      return !isEmpty(this.successMessage);
    },
    disablePromoCodeInput() {
      return this.applyingPromoCode || this.promoCodeSuccessful;
    },
    disablePromoCodeApplyBtn() {
      return this.disablePromoCodeInput || isEmpty(this.promoCode);
    },
    isPromoCodeValid() {
      return this.applyingPromoCode || isEmpty(this.errorMessage);
    },
    showSuccessAlert() {
      return this.canShowSuccessAlert && Boolean(this.successMessage);
    },
    promoCodeError() {
      return this.applyingPromoCode ? '' : this.errorMessage;
    },
  },
  methods: {
    applyPromoCode() {
      this.$emit('apply-promo-code', this.promoCode);
    },
    updatePromoCode() {
      this.$emit('promo-code-updated');
    },
  },
};
</script>

<template>
  <div>
    <gl-form-group
      :label="$options.i18n.label"
      class="gl-mt-6 gl-mb-4"
      :invalid-feedback="promoCodeError"
      :state="isPromoCodeValid"
    >
      <gl-form-input-group>
        <gl-form-input
          v-model="promoCode"
          size="md"
          :disabled="disablePromoCodeInput"
          @change="updatePromoCode"
        />
        <template #append>
          <gl-button
            category="secondary"
            :loading="applyingPromoCode"
            :disabled="disablePromoCodeApplyBtn"
            @click="applyPromoCode"
          >
            {{ $options.i18n.applyButtonText }}
          </gl-button>
        </template>
      </gl-form-input-group>
    </gl-form-group>
    <gl-alert v-if="showSuccessAlert" variant="success" :dismissible="false">
      {{ successMessage }}
    </gl-alert>
  </div>
</template>
