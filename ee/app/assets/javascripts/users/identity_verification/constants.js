import { s__, sprintf } from '~/locale';

export const PAGE_TITLE = s__('IdentityVerification|Help us keep GitLab secure');
export const PAGE_SUBTITLE = s__(
  "IdentityVerification|For added security, you'll need to verify your identity in a few quick steps.",
);

export const STEP_1_TITLE = s__('IdentityVerification|Step 1: Verify phone number');

export const PHONE_NUMBER_LABEL = s__('IdentityVerification|Phone number');
export const COUNTRY_LABEL = s__('IdentityVerification|International dial code');

export const INFO_TEXT = s__(
  'IdentityVerification|You will receive a text containing a code. Standard charges may apply.',
);

export const SEND_CODE = s__('IdentityVerification|Send code');

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

export const I18N_CC_FORM_SUBMIT = s__('IdentityVerification|Verify payment method');
export const I18N_CC_FORM_INFO = s__(
  'IdentityVerification|GitLab will not charge or store your payment information, it will only be used for verification.',
);
