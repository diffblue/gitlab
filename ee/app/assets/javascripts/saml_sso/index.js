import Vue from 'vue';

import ScimToken from './components/scim_token.vue';
import { AUTO_REDIRECT_TO_PROVIDER_BUTTON_SELECTOR } from './constants';

export const redirectUserWithSSOIdentity = () => {
  const signInButton = document.querySelector(AUTO_REDIRECT_TO_PROVIDER_BUTTON_SELECTOR);

  if (!signInButton) {
    return;
  }

  signInButton.click();
};

export const initScimTokenApp = () => {
  const el = document.getElementById('js-scim-token-app');

  if (!el) return null;

  const { endpointUrl, generateTokenPath } = el.dataset;

  return new Vue({
    el,
    provide: {
      initialEndpointUrl: endpointUrl,
      generateTokenPath,
    },
    render(createElement) {
      return createElement(ScimToken);
    },
  });
};
