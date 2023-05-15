import '~/pages/registrations/new';
import initPasswordValidator from 'ee/password/password_validator';
import { setupArkoseLabsForSignup } from 'ee/arkose_labs';

// Warning: initPasswordValidator has to run after initPasswordInput
// (which is executed when '~/pages/registrations/new' is imported)
initPasswordValidator();

if (gon.features.arkoseLabsSignupChallenge) {
  setupArkoseLabsForSignup();
}
