import Vue from 'vue';

import SCIMTokenToggleArea from 'ee/saml_providers/scim_token_toggle_area';

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

  if (!el) {
    // `scim_token_vue` feature flag is disabled, load legacy JS.
    const groupPath = document.querySelector('#issuer').value;

    // eslint-disable-next-line no-new
    new SCIMTokenToggleArea(
      '.js-generate-scim-token-container',
      '.js-scim-token-container',
      groupPath,
    );

    return false;
  }

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
