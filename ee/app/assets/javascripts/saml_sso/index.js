import Vue from 'vue';

import { parseBoolean } from '~/lib/utils/common_utils';
import ScimToken from './components/scim_token.vue';
import SamlAuthorize from './components/saml_authorize.vue';
import { AUTO_REDIRECT_TO_PROVIDER_BUTTON_SELECTOR, SAML_AUTHORIZE_SELECTOR } from './constants';

export const redirectUserWithSSOIdentity = () => {
  const signInButton = document.querySelector(AUTO_REDIRECT_TO_PROVIDER_BUTTON_SELECTOR);

  if (!signInButton) {
    return;
  }

  signInButton.click();
};

export const initSamlAuthorize = () => {
  const el = document.getElementById(SAML_AUTHORIZE_SELECTOR);

  if (!el) return null;

  const { groupName, groupUrl, rememberable, samlUrl, signInButtonText } = el.dataset;

  return new Vue({
    el,
    name: 'SamlAuthorizeRoot',
    provide: {
      groupName,
      groupUrl,
      rememberable: parseBoolean(rememberable),
      samlUrl,
      signInButtonText,
    },
    render(createElement) {
      return createElement(SamlAuthorize);
    },
  });
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
