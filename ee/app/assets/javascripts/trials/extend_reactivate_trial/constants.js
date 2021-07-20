import { s__ } from '~/locale';

export const TRIAL_ACTION_EXTEND = 'extend';
export const TRIAL_ACTION_REACTIVATE = 'reactivate';
export const TRIAL_ACTIONS = [TRIAL_ACTION_EXTEND, TRIAL_ACTION_REACTIVATE];

export const i18n = Object.freeze({
  planName: s__('Billings|%{planName} plan'),
  extend: {
    buttonText: s__('Billings|Extend trial'),
    modalText: s__(
      'Billings|By extending your trial, you will receive an additional 30 days of %{planName}. Your trial can be only extended once.',
    ),
    trialActionError: s__('Billings|An error occurred while extending your trial.'),
  },
  reactivate: {
    buttonText: s__('Billings|Reactivate trial'),
    modalText: s__(
      'Billings|By reactivating your trial, you will receive an additional 30 days of %{planName}. Your trial can be only reactivated once.',
    ),
    trialActionError: s__('Billings|An error occurred while reactivating your trial.'),
  },
});
