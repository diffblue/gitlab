import { redirectUserWithSSOIdentity } from 'ee/saml_sso';
import { GlTabsBehavior } from '~/tabs';
import UsernameValidator from '~/pages/sessions/new/username_validator';
import initConfirmDanger from '~/init_confirm_danger';

new GlTabsBehavior(document.querySelector('.new-session-tabs')); // eslint-disable-line no-new
new UsernameValidator(); // eslint-disable-line no-new
redirectUserWithSSOIdentity();
initConfirmDanger();
