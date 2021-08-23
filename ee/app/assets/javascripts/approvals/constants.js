import { __, s__ } from '~/locale';

export const TYPE_USER = 'user';
export const TYPE_GROUP = 'group';
export const TYPE_HIDDEN_GROUPS = 'hidden_groups';

export const BRANCH_FETCH_DELAY = 250;
export const ANY_BRANCH = {
  id: null,
  name: __('Any branch'),
};

export const RULE_TYPE_FALLBACK = 'fallback';
export const RULE_TYPE_REGULAR = 'regular';
export const RULE_TYPE_REPORT_APPROVER = 'report_approver';
export const RULE_TYPE_CODE_OWNER = 'code_owner';
export const RULE_TYPE_ANY_APPROVER = 'any_approver';
export const RULE_NAME_ANY_APPROVER = 'All Members';

export const VULNERABILITY_CHECK_NAME = 'Vulnerability-Check';
export const LICENSE_CHECK_NAME = 'License-Check';
export const COVERAGE_CHECK_NAME = 'Coverage-Check';

export const LICENSE_SCANNING = 'license_scanning';

export const APPROVAL_RULE_CONFIGS = {
  [VULNERABILITY_CHECK_NAME]: {
    title: s__('SecurityApprovals|Vulnerability-Check'),
    popoverText: s__(
      'SecurityApprovals|A merge request approval is required when a security report contains a new vulnerability.',
    ),
    documentationText: s__('SecurityApprovals|Learn more about Vulnerability-Check'),
  },
  [LICENSE_CHECK_NAME]: {
    title: s__('SecurityApprovals|License-Check'),
    popoverText: s__(
      'SecurityApprovals|A merge request approval is required when the license compliance report contains a denied license.',
    ),
    documentationText: s__('SecurityApprovals|Learn more about License-Check'),
  },
  [COVERAGE_CHECK_NAME]: {
    title: s__('SecurityApprovals|Coverage-Check'),
    popoverText: s__(
      'SecurityApprovals|A merge request approval is required when test coverage declines.',
    ),
    documentationText: s__('SecurityApprovals|Learn more about Coverage-Check'),
  },
};

export const APPROVALS_HELP_PATH = 'user/project/merge_requests/approvals/settings';

export const APPROVAL_SETTINGS_I18N = {
  saveChanges: __('Save changes'),
  loadingErrorMessage: s__(
    'ApprovalSettings|There was an error loading merge request approval settings.',
  ),
  savingErrorMessage: s__(
    'ApprovalSettings|There was an error updating merge request approval settings.',
  ),
  savingSuccessMessage: s__('ApprovalSettings|Merge request approval settings have been updated.'),
  lockedByAdmin: s__(
    'ApprovalSettings|This setting is configured at the instance level and can only be changed by an administrator.',
  ),
};

export const PROJECT_APPROVAL_SETTINGS_LABELS_I18N = {
  authorApprovalLabel: s__('ApprovalSettings|Prevent approval by author.'),
  preventMrApprovalRuleEditLabel: s__(
    'ApprovalSettings|Prevent editing approval rules in merge requests.',
  ),
  preventCommittersApprovalLabel: s__(
    'ApprovalSettings|Prevent approvals by users who add commits.',
  ),
  requireUserPasswordLabel: s__('ApprovalSettings|Require user password to approve.'),
  removeApprovalsOnPushLabel: s__(
    'ApprovalSettings|Remove all approvals when commits are added to the source branch.',
  ),
};

export const GROUP_APPROVAL_SETTINGS_LABELS_I18N = {
  ...PROJECT_APPROVAL_SETTINGS_LABELS_I18N,
  preventMrApprovalRuleEditLabel: s__(
    'ApprovalSettings|Prevent editing approval rules in projects and merge requests. ',
  ),
};

export const APPROVAL_DIALOG_I18N = {
  form: {
    approvalsRequiredLabel: s__('ApprovalRule|Approvals required'),
    approvalTypeLabel: s__('ApprovalRule|Approver Type'),
    approversLabel: s__('ApprovalRule|Add approvers'),
    nameLabel: s__('ApprovalRule|Rule name'),
    nameDescription: s__('ApprovalRule|Examples: QA, Security.'),
    protectedBranchLabel: s__('ApprovalRule|Target branch'),
    protectedBranchDescription: __(
      'Apply this approval rule to any branch or a specific protected branch.',
    ),
    scannersLabel: s__('ApprovalRule|Security scanners'),
    scannersSelectLabel: s__('ApprovalRule|Select scanners'),
    scannersDescription: s__(
      'ApprovalRule|Apply this approval rule to consider only the selected security scanners.',
    ),
    selectAllLabel: s__('ApprovalRule|Select All'),
    allScannersSelectedLabel: s__('ApprovalRule|All scanners'),
    multipleSelectedLabel: s__('ApprovalRule|%{firstLabel} +%{numberOfAdditionalLabels} more'),
    vulnerabilitiesAllowedLabel: s__('ApprovalRule|Vulnerabilities allowed'),
    vulnerabilitiesAllowedDescription: s__(
      'ApprovalRule|Number of vulnerabilities allowed before approval rule is triggered.',
    ),
    severityLevelsLabel: s__('ApprovalRule|Severity levels'),
    severityLevelsDescription: s__(
      'ApprovalRule|Apply this approval rule to consider only the selected severity levels.',
    ),
    severityLevelsSelectLabel: s__('ApprovalRule|Select severity levels'),
    allSeverityLevelsSelectedLabel: s__('ApprovalRule|All severity levels'),
  },
  validations: {
    approvalsRequiredNegativeNumber: __('Please enter a non-negative number'),
    approvalsRequiredNotNumber: __('Please enter a valid number'),
    approvalsRequiredMinimum: __(
      'Please enter a number greater than %{number} (from the project settings)',
    ),
    approversRequired: __('Please select and add a member'),
    branchesRequired: __('Please select a valid target branch'),
    ruleNameTaken: __('Rule name is already taken.'),
    ruleNameMissing: __('Please provide a name'),
    scannersRequired: s__('ApprovalRule|Please select at least one security scanner'),
    vulnerabilitiesAllowedMinimum: s__(
      'ApprovalRule|Please enter a number equal or greater than zero',
    ),
    severityLevelsRequired: s__('ApprovalRule|Please select at least one severity level'),
  },
};
