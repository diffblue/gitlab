import { s__ } from '~/locale';

export const PROJECT_COMPLIANCE_FRAMEWORK_I18N = {
  title: s__('ComplianceFramework|No compliance frameworks are set up yet'),
  ownerDescription: s__(
    'ComplianceFramework|Add a framework to %{linkStart}%{groupName}%{linkEnd} and it will appear here.',
  ),
  maintainerDescription: s__(
    'ComplianceFramework|After a framework is added to %{linkStart}%{groupName}%{linkEnd}, it will appear here.',
  ),
  buttonText: s__('ComplianceFramework|Add framework in %{groupName}'),
};

export const MOVE_PERSONAL_PROJECT_TO_GROUP_MODAL = 'move-personal-project-to-group-modal';
