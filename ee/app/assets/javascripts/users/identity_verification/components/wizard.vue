<script>
import { kebabCase } from 'lodash';
import { s__, sprintf } from '~/locale';
import { visitUrl } from '~/lib/utils/url_utility';

import { REDIRECT_TIMEOUT } from '../constants';
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
  inject: ['verificationSteps', 'initialVerificationState', 'successfulVerificationPath'],
  data() {
    return {
      stepsVerifiedState: this.initialVerificationState,
    };
  },
  computed: {
    activeStep() {
      const isIncomplete = (step) => !this.stepsVerifiedState[step];
      return this.orderedSteps.find(isIncomplete);
    },
    orderedSteps() {
      return [...this.verificationSteps].sort(
        (a, b) => this.stepsVerifiedState[b] - this.stepsVerifiedState[a],
      );
    },
    allStepsCompleted() {
      return !Object.entries(this.stepsVerifiedState).filter(([, completed]) => !completed).length;
    },
    isStandaloneEmailVerification() {
      return this.verificationSteps.length === 1;
    },
  },
  methods: {
    onStepCompleted(step) {
      this.stepsVerifiedState[step] = true;
      if (this.allStepsCompleted) {
        setTimeout(() => visitUrl(this.successfulVerificationPath), REDIRECT_TIMEOUT);
      }
    },
    methodComponent(method) {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      return `${kebabCase(method)}-verification`;
    },
    stepTitle(step, number) {
      const { ccStep, phoneStep, emailStep } = this.$options.i18n;
      const templates = {
        creditCard: ccStep,
        phone: phoneStep,
        email: emailStep,
      };
      return sprintf(templates[step], { stepNumber: number });
    },
  },
  i18n: {
    pageTitle: s__('IdentityVerification|Help us keep GitLab secure'),
    pageDescription: s__(
      "IdentityVerification|For added security, you'll need to verify your identity in a few quick steps.",
    ),
    ccStep: s__('IdentityVerification|Step %{stepNumber}: Verify a payment method'),
    phoneStep: s__('IdentityVerification|Step %{stepNumber}: Verify phone number'),
    emailStep: s__('IdentityVerification|Step %{stepNumber}: Verify email address'),
  },
};
</script>
<template>
  <div class="gl--flex-center">
    <div class="gl-flex-grow-1 gl-max-w-62">
      <header class="gl-text-center">
        <h2>{{ $options.i18n.pageTitle }}</h2>
        <p v-if="!isStandaloneEmailVerification">{{ $options.i18n.pageDescription }}</p>
      </header>
      <email-verification
        v-if="isStandaloneEmailVerification"
        :is-standalone="true"
        @completed="onStepCompleted(verificationSteps[0])"
      />
      <template v-for="(step, index) in orderedSteps" v-else>
        <verification-step
          :key="step"
          :title="stepTitle(step, index + 1)"
          :completed="stepsVerifiedState[step]"
          :is-active="step === activeStep"
        >
          <component :is="methodComponent(step)" @completed="onStepCompleted(step)" />
        </verification-step>
      </template>
    </div>
  </div>
</template>
