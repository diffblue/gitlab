import { __, s__ } from '~/locale';

export const I18N_DELETION_PROTECTION = {
  heading: s__('DeletionSettings|Deletion protection'),
  helpText: s__(
    'DeletionSettings|Retention period that deleted groups and projects will remain restorable. Personal projects are always deleted immediately. Some groups can opt-out their projects.',
  ),
  helpTextFeatureFlagEnabled: s__(
    'DeletionSettings|Period that deleted groups and projects will remain restorable for. Personal projects are always deleted immediately.',
  ),
  learnMore: __('Learn more.'),
  keepDeleted: s__('DeletionSettings|Keep deleted'),
  deleteImmediately: s__('DeletionSettings|None, delete immediately'),
  for: __('for'),
  days: __('days'),
  groupsOnly: __('groups only'),
  groupsAndProjects: __('groups and projects'),
};
