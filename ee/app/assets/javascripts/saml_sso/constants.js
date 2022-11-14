import { __, s__ } from '~/locale';

export const AUTO_REDIRECT_TO_PROVIDER_BUTTON_SELECTOR = '#js-auto-redirect-to-provider';
export const REMEMBER_ME_PARAM = 'remember_me';
export const SAML_AUTHORIZE_SELECTOR = 'js-saml-authorize';
export const I18N = {
  authorizeAlert: s__(
    'SAML|To allow %{groupName} to manage your GitLab account %{username} after you sign in successfully using single sign-on, select %{strongStart}Authorize%{strongEnd}.',
  ),
  authorizeButton: __('Authorize'),
  authorizeInfo: s__('SAML|The %{groupName} group allows you to sign in using single sign-on.'),
  authorizeTitle: s__('SAML|Allow %{groupName} to sign you in?'),
  rememberMe: __('Remember me'),
};
