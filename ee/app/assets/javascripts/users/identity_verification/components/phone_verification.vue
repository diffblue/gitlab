<script>
import InternationalPhoneInput from './international_phone_input.vue';
import VerifyPhoneVerificationCode from './verify_phone_verification_code.vue';

export default {
  name: 'PhoneVerification',
  components: {
    InternationalPhoneInput,
    VerifyPhoneVerificationCode,
  },
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
  </div>
</template>
