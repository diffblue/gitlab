import { s__ } from '~/locale';

export const I18N = {
  title: s__('RegistrationVerification|Enable free CI/CD minutes'),
  description: s__(
    "RegistrationVerification|To keep GitLab spam and abuse free we ask that you verify your identity with a valid payment method, such as a debit or credit card. Until then, you can't use free CI/CD minutes to build your application.",
  ),
  disclaimer: s__(
    'RegistrationVerification|GitLab will not charge your card, it will only be used for validation.',
  ),
  submit: s__('RegistrationVerification|Validate account'),
  skip: s__('RegistrationVerification|Skip this for now'),
  skip_explanation: s__(
    'RegistrationVerification|You can alway verify your account at a later time.',
  ),
  skip_confirmation: {
    title: s__('RegistrationVerification|Are you sure you want to skip this step?'),
    content: s__(
      'RegistrationVerification|Pipelines using shared GitLab runners will fail until you validate your account.',
    ),
    link: s__("RegistrationVerification|Yes, I'd like to skip"),
  },
};
export const IFRAME_MINIMUM_HEIGHT = 312;
export const EVENT_LABEL = 'registration_verification';
export const MOUNTED_EVENT = 'shown';
export const SKIPPED_EVENT = 'skipped';
export const VERIFIED_EVENT = 'verified';
