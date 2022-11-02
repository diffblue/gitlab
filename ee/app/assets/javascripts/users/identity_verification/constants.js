import { s__, sprintf } from '~/locale';

export const PAGE_TITLE = s__('IdentityVerification|Help us keep GitLab secure');
export const PAGE_SUBTITLE = s__(
  "IdentityVerification|For added security, you'll need to verify your identity in a few quick steps.",
);

export const PHONE_NUMBER_LABEL = s__('IdentityVerification|Phone number');
export const COUNTRY_LABEL = s__('IdentityVerification|International dial code');

// follows E.164 standard - https://en.wikipedia.org/wiki/E.164
export const MAX_PHONE_NUMBER_LENGTH = 12;

export const PHONE_NUMBER_BLANK_ERROR = s__("IdentityVerification|Phone number can't be blank.");
export const PHONE_NUMBER_NAN_ERROR = s__(
  'IdentityVerification|Phone number must contain only digits.',
);
export const PHONE_NUMBER_LENGTH_ERROR = sprintf(
  s__(`IdentityVerification|Phone number must be %{maxLength} digits or fewer.`),
  {
    maxLength: MAX_PHONE_NUMBER_LENGTH,
  },
);

export const I18N_EMAIL_EMPTY_CODE = s__('IdentityVerification|Enter a code.');
export const I18N_EMAIL_INVALID_CODE = s__('IdentityVerification|Enter a valid code.');
export const I18N_EMAIL_RESEND_SUCCESS = s__('IdentityVerification|A new code has been sent.');
export const I18N_EMAIL_REQUEST_ERROR = s__(
  'IdentityVerification|Something went wrong. Please try again.',
);
