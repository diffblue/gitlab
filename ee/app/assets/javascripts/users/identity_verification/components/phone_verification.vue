<script>
import { GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';
import InternationalPhoneInput from './international_phone_input.vue';
import VerifyPhoneVerificationCode from './verify_phone_verification_code.vue';

export default {
  name: 'PhoneVerification',
  components: {
    GlButton,
    InternationalPhoneInput,
    VerifyPhoneVerificationCode,
  },
  inject: ['offerPhoneNumberExemption'],
  data() {
    return {
      stepIndex: 1,
      phoneNumber: {},
    };
  },
  methods: {
    goToStepTwo(phoneNumber) {
      this.stepIndex = 2;
      this.phoneNumber = phoneNumber;
    },
    goToStepOne() {
      this.stepIndex = 1;
    },
    setVerified() {
      this.$emit('completed');
    },
  },
  i18n: {
    verifyWithCreditCard: s__('IdentityVerification|Verify with a credit card instead?'),
  },
};
</script>
<template>
  <div>
    <international-phone-input
      v-show="stepIndex == 1"
      @next="goToStepTwo"
      @skip-verification="setVerified"
    />
    <verify-phone-verification-code
      v-show="stepIndex == 2"
      :latest-phone-number="phoneNumber"
      @back="goToStepOne"
      @verified="setVerified"
    />
    <gl-button
      v-if="offerPhoneNumberExemption"
      block
      variant="link"
      class="gl-mt-5 gl-font-sm"
      @click="$emit('exemptionRequested')"
      >{{ $options.i18n.verifyWithCreditCard }}</gl-button
    >
  </div>
</template>
