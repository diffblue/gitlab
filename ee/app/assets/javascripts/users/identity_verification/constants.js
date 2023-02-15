import { s__, sprintf } from '~/locale';

// follows E.164 standard - https://en.wikipedia.org/wiki/E.164
export const MAX_PHONE_NUMBER_LENGTH = 12;
export const DEFAULT_COUNTRY = 'US';
export const DEFAULT_INTERNATIONAL_DIAL_CODE = '1';

export const I18N_PHONE_NUMBER_BLANK_ERROR = s__('IdentityVerification|Phone number is required.');
export const I18N_PHONE_NUMBER_NAN_ERROR = s__(
  'IdentityVerification|Phone number must contain only digits.',
);
export const I18N_PHONE_NUMBER_LENGTH_ERROR = sprintf(
  s__(`IdentityVerification|Phone number must be %{maxLength} digits or fewer.`),
  {
    maxLength: MAX_PHONE_NUMBER_LENGTH,
  },
);

export const I18N_VERIFICATION_CODE_BLANK_ERROR = s__(
  "IdentityVerification|Verification code can't be blank.",
);
export const I18N_VERIFICATION_CODE_NAN_ERROR = s__(
  'IdentityVerification|Verification code must be a number.',
);

export const I18N_EMAIL_EMPTY_CODE = s__('IdentityVerification|Enter a code.');
export const I18N_EMAIL_INVALID_CODE = s__('IdentityVerification|Enter a valid code.');
export const I18N_EMAIL_RESEND_SUCCESS = s__('IdentityVerification|A new code has been sent.');
export const I18N_GENERIC_ERROR = s__(
  'IdentityVerification|Something went wrong. Please try again.',
);

export const REDIRECT_TIMEOUT = 1500;
