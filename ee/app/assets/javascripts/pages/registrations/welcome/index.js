import 'ee/registrations/welcome/jobs_to_be_done';
import { initWelcomeIndex } from 'ee/registrations/welcome';
import Tracking from '~/tracking';

initWelcomeIndex();

Tracking.enableFormTracking({
  forms: { allow: ['js-users-signup-welcome'] },
});
