import { initSamlAuthorize, redirectUserWithSSOIdentity } from 'ee/saml_sso';
import UsernameValidator from '~/pages/sessions/new/username_validator';
import initConfirmDanger from '~/init_confirm_danger';

new UsernameValidator(); // eslint-disable-line no-new
initSamlAuthorize();
redirectUserWithSSOIdentity();
initConfirmDanger();
