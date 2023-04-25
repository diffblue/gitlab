import { __, s__ } from '~/locale';

export const TYPE_USER = 'user';
export const TYPE_GROUP = 'group';
export const TYPE_HIDDEN_GROUPS = 'hidden_groups';

export const RULE_TYPE_FALLBACK = 'fallback';
export const RULE_TYPE_REGULAR = 'regular';
export const RULE_TYPE_REPORT_APPROVER = 'report_approver';
export const RULE_TYPE_CODE_OWNER = 'code_owner';
export const RULE_TYPE_ANY_APPROVER = 'any_approver';
export const RULE_NAME_ANY_APPROVER = 'All Members';

export const LICENSE_CHECK_NAME = 'License-Check';
export const COVERAGE_CHECK_NAME = 'Coverage-Check';

export const REPORT_TYPE_LICENSE_SCANNING = 'license_scanning';
export const REPORT_TYPE_CODE_COVERAGE = 'code_coverage';

export const APPROVAL_RULE_CONFIGS = {
  [COVERAGE_CHECK_NAME]: {
    title: s__('SecurityApprovals|Coverage-Check'),
    popoverText: s__(
      'SecurityApprovals|A merge request approval is required when test coverage declines.',
    ),
    documentationText: s__('SecurityApprovals|Learn more about Coverage-Check'),
    reportType: REPORT_TYPE_CODE_COVERAGE,
  },
};

export const APPROVAL_SETTINGS_I18N = {
  learnMore: __('Learn more.'),
  approvalSettingsHeader: __('Approval settings'),
  approvalSettingsDescription: __('Define how approval rules are applied to merge requests.'),
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
  lockedByGroupOwner: s__(
    'ApprovalSettings|This setting is configured in %{groupName} and can only be changed in the group settings by an administrator or group owner.',
  ),
};

export const PROJECT_APPROVAL_SETTINGS_LABELS_I18N = {
  authorApprovalLabel: s__('ApprovalSettings|Prevent approval by author'),
  preventMrApprovalRuleEditLabel: s__(
    'ApprovalSettings|Prevent editing approval rules in merge requests',
  ),
  preventCommittersApprovalLabel: s__(
    'ApprovalSettings|Prevent approvals by users who add commits',
  ),
  requireUserPasswordLabel: s__('ApprovalSettings|Require user password to approve'),
  whenCommitAddedLabel: s__('ApprovalSettings|When a commit is added:'),
  keepApprovalsLabel: s__('ApprovalSettings|Keep approvals'),
  removeApprovalsOnPushLabel: s__('ApprovalSettings|Remove all approvals'),
  selectiveCodeOwnerRemovalsLabel: s__(
    'ApprovalSettings|Remove approvals by Code Owners if their files changed',
  ),
};

export const GROUP_APPROVAL_SETTINGS_LABELS_I18N = {
  ...PROJECT_APPROVAL_SETTINGS_LABELS_I18N,
  preventMrApprovalRuleEditLabel: s__(
    'ApprovalSettings|Prevent editing approval rules in projects and merge requests.',
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
      'Apply this approval rule to all branches or a specific protected branch.',
    ),
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
  },
};

export const MR_APPROVALS_PROMO_DISMISSED = 'mr_approvals_promo.dismissed';
export const MR_APPROVALS_PROMO_TRACKING_EVENTS = {
  learnMoreClick: { action: 'click_link', label: 'learn_more_merge_approval' },
  tryNowClick: { action: 'click_button', label: 'start_trial' },
  collapsePromo: { action: 'click_button', label: 'collapse_approval_rules' },
  expandPromo: { action: 'click_button', label: 'expand_approval_rules' },
};
export const MR_APPROVALS_PROMO_I18N = {
  accordionTitle: s__('ApprovalRule|Approval rules'),
  learnMore: s__('ApprovalRule|Learn more about merge request approval rules.'),
  promoTitle: s__("ApprovalRule|Improve your organization's code review with required approvals."),
  summary: __('Approvals are optional.'),
  tryNow: s__('ApprovalRule|Try for free'),
  valueStatements: [
    s__('ApprovalRule|Select eligible approvers by expertise or files changed.'),
    s__('ApprovalRule|Increase quality and maintain standards.'),
    s__('ApprovalRule|Reduce your time to merge.'),
  ],
};
