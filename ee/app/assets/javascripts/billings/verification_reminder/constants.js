import { s__ } from '~/locale';

export const FEATURE_NAME = 'verification_reminder';
export const DOCS_LINK = 'https://docs.gitlab.com/runner/install/';
export const EVENT_LABEL = 'verification_reminder';
export const MOUNTED_EVENT = 'shown';
export const DISMISS_EVENT = 'dismissed';
export const OPEN_DOCS_EVENT = 'clicked_docs_link';
export const START_VERIFICATION_EVENT = 'start_verification';
export const SUCCESSFUL_VERIFICATION_EVENT = 'successful_verification';
export const I18N = {
  warningAlert: {
    title: s__(
      'VerificationReminder|Pipeline failing? To keep GitLab spam and abuse free we ask that you verify your identity.',
    ),
    message: s__(
      'VerificationReminder|Until then, shared runners will be unavailable. %{validateLinkStart}Validate your account%{validateLinkEnd} or %{docsLinkStart}use your own runners%{docsLinkEnd}.',
    ),
  },
  successAlert: {
    title: s__('VerificationReminder|Your account has been validated'),
    message: s__(
      'VerificationReminder|You’ll now be able to take advantage of free CI/CD minutes on shared runners.',
    ),
  },
};
