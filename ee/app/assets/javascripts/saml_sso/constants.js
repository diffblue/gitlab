import { __, s__ } from '~/locale';

export const AUTO_REDIRECT_TO_PROVIDER_BUTTON_SELECTOR = '#js-auto-redirect-to-provider';
export const REMEMBER_ME_PARAM = 'remember_me';
export const SAML_AUTHORIZE_SELECTOR = 'js-saml-authorize';
export const I18N = {
  rememberMe: __('Remember me'),
  signInInfo: s__(
    'SAML|To access %{groupName}, you must sign in using single sign-on through an external sign-in page.',
  ),
  signInTitle: s__('SAML|Sign in to %{groupName}'),
};
