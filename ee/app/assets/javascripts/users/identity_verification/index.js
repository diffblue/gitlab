import Vue from 'vue';
import apolloProvider from 'ee/subscriptions/buy_addons_shared/graphql';

import IdentityVerificationWizard from './components/wizard.vue';

export const initIdentityVerification = () => {
  const el = document.getElementById('js-identity-verification');

  if (!el) {
    return false;
  }

  return new Vue({
    el,
    apolloProvider,
    name: 'IdentityVerificationRoot',
    render(createElement) {
      return createElement(IdentityVerificationWizard);
    },
  });
};
