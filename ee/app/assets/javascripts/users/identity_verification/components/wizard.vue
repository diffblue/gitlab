<script>
import { kebabCase } from 'lodash';
import { sprintf } from '~/locale';
import {
  PAGE_TITLE,
  I18N_CC_VERIFICATION,
  I18N_EMAIL_VERIFICATION,
  I18N_PHONE_VERIFICATION,
} from '../constants';
import EmailVerification from './email_verification.vue';
import CreditCardVerification from './credit_card_verification.vue';
import PhoneVerification from './phone_verification.vue';
import VerificationStep from './verification_step.vue';

export default {
  name: 'IdentityVerificationWizard',
  components: {
    CreditCardVerification,
    PhoneVerification,
    EmailVerification,
    VerificationStep,
  },
  inject: ['verificationSteps', 'initialVerificationState'],
  data() {
    return {
      stepsVerifiedState: this.initialVerificationState,
    };
  },
  computed: {
    activeStep() {
      const isIncomplete = (step) => !this.stepsVerifiedState[step];
      return this.verificationSteps.find(isIncomplete);
    },
  },
  methods: {
    onStepCompleted(step) {
      this.stepsVerifiedState[step] = true;
    },
    methodComponent(method) {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      return `${kebabCase(method)}-verification`;
    },
    stepTitle(step, number) {
      const templates = {
        creditCard: I18N_CC_VERIFICATION.title,
        phone: I18N_PHONE_VERIFICATION.title,
        email: I18N_EMAIL_VERIFICATION.title,
      };
      return sprintf(templates[step], { stepNumber: number });
    },
  },
  i18n: {
    PAGE_TITLE,
  },
};
</script>
<template>
  <div class="gl--flex-center">
    <div class="gl-flex-grow-1 gl-max-w-62">
      <header class="gl-text-center">
        <h2>{{ $options.i18n.PAGE_TITLE }}</h2>
      </header>
      <component
        :is="methodComponent(verificationSteps[0])"
        v-if="verificationSteps.length === 1"
      />
      <template v-for="(step, index) in verificationSteps" v-else>
        <verification-step
          :key="step"
          :title="stepTitle(step, index + 1)"
          :completed="stepsVerifiedState[step]"
          :is-active="step === activeStep"
        >
          <component :is="methodComponent(step)" @completed="() => onStepCompleted(step)" />
        </verification-step>
      </template>
    </div>
  </div>
</template>
