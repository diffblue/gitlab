import '~/pages/sessions/index';
import { trackFreeTrialAccountSubmissions } from '~/google_tag_manager';

import NoEmojiValidator from '~/emoji/no_emoji_validator';
import LengthValidator from '~/pages/sessions/new/length_validator';
import SigninTabsMemoizer from '~/pages/sessions/new/signin_tabs_memoizer';
import UsernameValidator from '~/pages/sessions/new/username_validator';
import EmailFormatValidator from '~/pages/sessions/new/email_format_validator';
import Tracking from '~/tracking';

new UsernameValidator(); // eslint-disable-line no-new
new LengthValidator(); // eslint-disable-line no-new
new SigninTabsMemoizer(); // eslint-disable-line no-new
new NoEmojiValidator(); // eslint-disable-line no-new

if (gon.features.trialEmailValidation) {
  new EmailFormatValidator(); // eslint-disable-line no-new
}

trackFreeTrialAccountSubmissions();

Tracking.enableFormTracking({
  forms: { allow: ['new_user'] },
});
