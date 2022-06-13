import { __, s__ } from '~/locale';

export const I18N_DELETION_PROTECTION = {
  heading: s__('AdminSettings|Deletion protection'),
  helpText: s__(
    'AdminSettings|Retention period that deleted groups and projects will remain restorable. Personal projects are always deleted immediately. Some groups can opt-out their projects.',
  ),
  learnMore: __('Learn more.'),
  keepDeleted: s__('AdminSettings|Keep deleted'),
  deleteImmediately: s__('AdminSettings|None, delete immediately'),
  for: __('for'),
  days: __('days'),
  groupsOnly: __('groups only'),
  groupsAndProjects: __('groups and projects'),
};
