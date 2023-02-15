import Vue from 'vue';
import apolloProvider from 'ee/subscriptions/buy_addons_shared/graphql';
import { convertArrayToCamelCase, convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

import IdentityVerificationWizard from './components/wizard.vue';

export const initIdentityVerification = () => {
  const el = document.getElementById('js-identity-verification');

  if (!el) return false;

  const {
    email,
    creditCard,
    phoneNumber,
    verificationState,
    verificationMethods,
    successfulVerificationPath,
  } = convertObjectPropsToCamelCase(JSON.parse(el.dataset.data), { deep: true });

  return new Vue({
    el,
    apolloProvider,
    name: 'IdentityVerificationRoot',
    provide: {
      email,
      creditCard,
      phoneNumber,
      verificationSteps: convertArrayToCamelCase(verificationMethods),
      initialVerificationState: verificationState,
      successfulVerificationPath,
    },
    render: (createElement) => createElement(IdentityVerificationWizard),
  });
};
