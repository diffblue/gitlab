import 'ee/registrations/welcome/jobs_to_be_done';
import { initWelcomeIndex } from 'ee/registrations/welcome';
import { saasTrialWelcome } from '~/google_tag_manager';
import Tracking from '~/tracking';

initWelcomeIndex();
saasTrialWelcome();
Tracking.enableFormTracking({
  forms: { allow: ['js-users-signup-welcome'] },
});
