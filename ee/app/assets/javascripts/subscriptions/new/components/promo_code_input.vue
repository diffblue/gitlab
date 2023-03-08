<script>
import {
  GlButton,
  GlFormGroup,
  GlFormInputGroup,
  GlFormInput,
  GlAlert,
  GlSprintf,
  GlLink,
} from '@gitlab/ui';
import isEmpty from 'lodash/isEmpty';
import { s__, __ } from '~/locale';
import { PROMO_CODE_TERMS_LINK, PROMO_CODE_SUCCESS_MESSAGE } from 'ee/subscriptions/new/constants';

const i18n = Object.freeze({
  label: s__('Checkout|Coupon code (optional)'),
  applyButtonText: __('Apply'),
});

export default {
  name: 'PromoCodeInput',
  components: { GlButton, GlFormGroup, GlFormInputGroup, GlFormInput, GlAlert, GlSprintf, GlLink },
  props: {
    showSuccessAlert: {
      type: Boolean,
      required: false,
      default: false,
    },
    isParentFormLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    isApplyingPromoCode: {
      type: Boolean,
      required: false,
      default: false,
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
    disablePromoCodeInput() {
      return this.isParentFormLoading || this.showSuccessAlert;
    },
    disablePromoCodeApplyBtn() {
      return this.disablePromoCodeInput || isEmpty(this.promoCode);
    },
    isPromoCodeValid() {
      return isEmpty(this.promoCodeError);
    },
    promoCodeError() {
      return this.isParentFormLoading ? '' : this.errorMessage;
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
  PROMO_CODE_TERMS_LINK,
  PROMO_CODE_SUCCESS_MESSAGE,
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
          data-qa-selector="promo_code"
          :disabled="disablePromoCodeInput"
          @change="updatePromoCode"
        />
        <template #append>
          <gl-button
            category="secondary"
            data-qa-selector="apply_promo_code"
            :loading="isApplyingPromoCode"
            :disabled="disablePromoCodeApplyBtn"
            @click="applyPromoCode"
          >
            {{ $options.i18n.applyButtonText }}
          </gl-button>
        </template>
      </gl-form-input-group>
    </gl-form-group>
    <gl-alert
      v-if="showSuccessAlert"
      variant="success"
      :dismissible="false"
      data-qa-selector="promo_alert"
    >
      <gl-sprintf :message="$options.PROMO_CODE_SUCCESS_MESSAGE">
        <template #link="{ content }">
          <gl-link
            class="gl-text-decoration-none!"
            :href="$options.PROMO_CODE_TERMS_LINK"
            target="_blank"
            >{{ content }}</gl-link
          >
        </template>
      </gl-sprintf>
    </gl-alert>
  </div>
</template>
