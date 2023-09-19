import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export const BLOCK_PROTECTED_BRANCH_MODIFICATION = 'block_protected_branch_modification';
export const PREVENT_APPROVAL_BY_MR_AUTHOR = 'prevent_approval_by_merge_request_author';
export const PREVENT_APPROVAL_BY_ANYONE_WHO_ADDED_COMMIT =
  'prevent_approval_by_anyone_who_added_commit';
export const REMOVE_ALL_APPROVALS_WHEN_COMMIT_ADDED = 'remove_all_approvals_when_commit_added';
export const REQUIRE_USER_PASSWORD_TO_APPROVE = 'require_user_password_to_approve';

export const protectedBranchesConfiguration = {
  [BLOCK_PROTECTED_BRANCH_MODIFICATION]: {
    enabled: true,
  },
};
export const PROTECTED_BRANCHES_CONFIGURATION_KEYS = [BLOCK_PROTECTED_BRANCH_MODIFICATION];

export const MERGE_REQUEST_CONFIGURATION_KEYS = [
  PREVENT_APPROVAL_BY_MR_AUTHOR,
  PREVENT_APPROVAL_BY_ANYONE_WHO_ADDED_COMMIT,
  REMOVE_ALL_APPROVALS_WHEN_COMMIT_ADDED,
  REQUIRE_USER_PASSWORD_TO_APPROVE,
];

export const mergeRequestConfiguration = {
  [PREVENT_APPROVAL_BY_MR_AUTHOR]: {
    enabled: true,
  },
  [PREVENT_APPROVAL_BY_ANYONE_WHO_ADDED_COMMIT]: {
    enabled: true,
  },
  [REMOVE_ALL_APPROVALS_WHEN_COMMIT_ADDED]: {
    enabled: true,
  },
  [REQUIRE_USER_PASSWORD_TO_APPROVE]: {
    enabled: true,
  },
};

export const SETTINGS_HUMANIZED_STRINGS = {
  [BLOCK_PROTECTED_BRANCH_MODIFICATION]: s__(
    'ScanResultPolicy|Prevent branch protection modification',
  ),
  [PREVENT_APPROVAL_BY_MR_AUTHOR]: s__(
    "ScanResultPolicy|Prevent approval by merge request's author",
  ),
  [PREVENT_APPROVAL_BY_ANYONE_WHO_ADDED_COMMIT]: s__(
    'ScanResultPolicy|Prevent approval by anyone who added a commit',
  ),
  [REMOVE_ALL_APPROVALS_WHEN_COMMIT_ADDED]: s__(
    'ScanResultPolicy|Remove all approvals when commit is added',
  ),
  [REQUIRE_USER_PASSWORD_TO_APPROVE]: s__(
    "ScanResultPolicy|Require the user's password to approve",
  ),
};

export const SETTINGS_TOOLTIP = {
  [PREVENT_APPROVAL_BY_MR_AUTHOR]: s__(
    'ScanResultPolicy|When enabled, two person approval will be required on all MRs as merge request authors cannot approve their own MRs and merge them unilaterally',
  ),
};

export const SETTINGS_POPOVER_STRINGS = {
  [BLOCK_PROTECTED_BRANCH_MODIFICATION]: {
    title: s__('ScanResultPolicy|Recommended setting'),
    description: s__(
      'ScanResultPolicy|You have selected any protected branch option as a condition. To better protect your project, it is recommended to enable the protect branch settings. %{linkStart}Learn more.%{linkEnd}',
    ),
    featureName: 'security_policy_protected_branch_modification',
  },
};

export const SETTINGS_LINKS = {
  [BLOCK_PROTECTED_BRANCH_MODIFICATION]: helpPagePath(
    '/user/application_security/policies/scan-result-policies.html',
  ),
};

export const VALID_APPROVAL_SETTINGS = [
  ...Object.keys(protectedBranchesConfiguration),
  ...Object.keys(mergeRequestConfiguration),
];
/**
 * Build settings based on provided flags, scalable for more flags in future
 * @param hasAnyMergeRequestRule
 * @returns {Object} final settings
 */
export const buildConfig = ({ hasAnyMergeRequestRule } = { hasAnyMergeRequestRule: false }) => {
  let configuration = { ...protectedBranchesConfiguration };

  const extendConfiguration = (predicate, extension) => {
    if (predicate) {
      configuration = {
        ...configuration,
        ...extension,
      };
    }
  };

  extendConfiguration(hasAnyMergeRequestRule, mergeRequestConfiguration);

  return configuration;
};

/**
 * Map dynamic approval settings to defined list and update only enable property
 * @param settings
 * @param hasAnyMergeRequestRule
 * @returns {Object}
 */
export const buildSettingsList = (
  { settings, hasAnyMergeRequestRule } = {
    settings: {},
    hasAnyMergeRequestRule: false,
  },
) => {
  const configuration = buildConfig({ hasAnyMergeRequestRule });

  return Object.keys(configuration).reduce((acc, setting) => {
    const hasEnabledProperty = settings?.[setting] && 'enabled' in settings[setting];
    const { enabled } = hasEnabledProperty ? settings[setting] : configuration[setting];

    acc[setting] = {
      ...configuration[setting],
      enabled,
    };

    return acc;
  }, {});
};
