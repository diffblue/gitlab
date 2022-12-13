<script>
import { GlButton, GlFormGroup, GlFormInputGroup, GlFormInput } from '@gitlab/ui';
import { s__, __ } from '~/locale';

const i18n = Object.freeze({
  label: s__('Checkout|Coupon code (optional)'),
  applyButtonText: __('Apply'),
});

export default {
  name: 'PromoCodeInput',
  components: { GlButton, GlFormGroup, GlFormInputGroup, GlFormInput },
  i18n,
  data() {
    return {
      promoCode: '',
    };
  },
  methods: {
    applyPromoCode() {
      this.$emit('applyPromoCode', this.promoCode);
    },
  },
};
</script>

<template>
  <gl-form-group :label="$options.i18n.label" class="gl-my-6">
    <gl-form-input-group>
      <gl-form-input v-model="promoCode" size="md" />
      <template #append>
        <gl-button category="secondary" @click="applyPromoCode">
          {{ $options.i18n.applyButtonText }}
        </gl-button>
      </template>
    </gl-form-input-group>
  </gl-form-group>
</template>
