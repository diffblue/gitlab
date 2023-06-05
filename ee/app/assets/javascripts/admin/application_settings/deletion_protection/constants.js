import { __, s__ } from '~/locale';

export const I18N_DELETION_PROTECTION = {
  label: s__('DeletionSettings|Deletion protection'),
  helpText: s__(
    'DeletionSettings|Period that deleted groups and projects will remain restorable for. Personal projects are always deleted immediately.',
  ),
  learnMore: __('Learn more.'),
  days: __('days'),
};
