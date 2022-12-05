import '~/pages/registrations/new/index';
import initPasswordValidator from 'ee/password/password_validator';
import { setupArkoseLabsForSignup } from 'ee/arkose_labs';

initPasswordValidator();

if (gon.features.arkoseLabsSignupChallenge) {
  setupArkoseLabsForSignup();
}
