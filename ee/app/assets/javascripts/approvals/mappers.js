import {
  convertObjectPropsToCamelCase,
  convertObjectPropsToSnakeCase,
} from '~/lib/utils/common_utils';
import {
  RULE_TYPE_REGULAR,
  RULE_TYPE_ANY_APPROVER,
  APPROVAL_RULE_CONFIGS,
  RULE_TYPE_REPORT_APPROVER,
} from './constants';

const visibleTypes = new Set([RULE_TYPE_ANY_APPROVER, RULE_TYPE_REGULAR]);

function withDefaultEmptyRule(rules = []) {
  if (rules && rules.length > 0) {
    return rules;
  }

  return [
    {
      id: null,
      name: '',
      approvalsRequired: 0,
      minApprovalsRequired: 0,
      approvers: [],
      containsHiddenGroups: false,
      users: [],
      groups: [],
      ruleType: RULE_TYPE_ANY_APPROVER,
      protectedBranches: [],
      appliesToAllProtectedBranches: false,
      overridden: false,
    },
  ];
}

function ruleTypeFromName(ruleName) {
  return ruleName in APPROVAL_RULE_CONFIGS ? RULE_TYPE_REPORT_APPROVER : undefined;
}

function reportTypeFromName(ruleName) {
  return APPROVAL_RULE_CONFIGS[ruleName]?.reportType;
}

export const mapApprovalRuleRequest = (req) => ({
  ...convertObjectPropsToSnakeCase(req),
  report_type: reportTypeFromName(req.name),
  rule_type: ruleTypeFromName(req.name),
});

export const mapApprovalFallbackRuleRequest = (req) => ({
  fallback_approvals_required: req.approvalsRequired,
});

export const mapApprovalRuleResponse = (res) => ({
  ...convertObjectPropsToCamelCase(res),
  hasSource: Boolean(res.source_rule),
  minApprovalsRequired: 0,
});

export const mapApprovalSettingsResponse = (res) => ({
  rules: withDefaultEmptyRule(res.map(mapApprovalRuleResponse)),
  fallbackApprovalsRequired: res.fallback_approvals_required,
});

/**
 * Map the sourced approval rule response for the MR view
 *
 * This rule is sourced from project settings, which implies:
 * - Not a real MR rule, so no "id".
 * - The approvals required are the minimum.
 */
export const mapMRSourceRule = ({ id, ...rule }) => ({
  ...rule,
  hasSource: true,
  sourceId: id,
  minApprovalsRequired: 0,
});

/**
 * Map the approval settings response for the MR view
 *
 * - Only show regular rules.
 * - If needed, extract the fallback approvals required
 *   from the fallback rule.
 */
export const mapMRApprovalSettingsResponse = (res) => {
  const rules = res.rules.filter(({ rule_type }) => visibleTypes.has(rule_type));

  const fallbackApprovalsRequired = res.fallback_approvals_required || 0;

  return {
    rules: withDefaultEmptyRule(
      rules
        .map(mapApprovalRuleResponse)
        .map(res.approval_rules_overwritten ? (x) => x : mapMRSourceRule),
    ),
    fallbackApprovalsRequired,
    minFallbackApprovalsRequired: 0,
  };
};

const invertApprovalSetting = ({ value, ...rest }) => ({ value: !value, ...rest });

export const mergeRequestApprovalSettingsMappers = {
  mapDataToState: (data) =>
    convertObjectPropsToCamelCase(
      {
        preventAuthorApproval: invertApprovalSetting(data.allow_author_approval),
        preventMrApprovalRuleEdit: invertApprovalSetting(
          data.allow_overrides_to_approver_list_per_merge_request,
        ),
        requireUserPassword: data.require_password_to_approve,
        removeApprovalsOnPush: invertApprovalSetting(data.retain_approvals_on_push),
        preventCommittersApproval: invertApprovalSetting(data.allow_committer_approval),
        selectiveCodeOwnerRemovals: data.selective_code_owner_removals,
      },
      { deep: true },
    ),
  mapStateToPayload: ({ settings }) => ({
    allow_author_approval: !settings.preventAuthorApproval.value,
    allow_overrides_to_approver_list_per_merge_request: !settings.preventMrApprovalRuleEdit.value,
    require_password_to_approve: settings.requireUserPassword.value,
    retain_approvals_on_push: !settings.removeApprovalsOnPush.value,
    selective_code_owner_removals: settings.selectiveCodeOwnerRemovals.value,
    allow_committer_approval: !settings.preventCommittersApproval.value,
  }),
};
