import '~/pages/registrations/new/index';
import PasswordValidator from 'ee/password/password_validator';
import { setupArkoseLabsForSignup } from 'ee/arkose_labs';

new PasswordValidator(); // eslint-disable-line no-new

if (gon.features.arkoseLabsSignupChallenge) {
  setupArkoseLabsForSignup();
}
