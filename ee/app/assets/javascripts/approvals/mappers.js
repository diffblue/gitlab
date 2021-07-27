import { RULE_TYPE_REGULAR, RULE_TYPE_ANY_APPROVER } from './constants';

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
      overridden: false,
    },
  ];
}

export const mapApprovalRuleRequest = (req) => ({
  name: req.name,
  approvals_required: req.approvalsRequired,
  users: req.users,
  groups: req.groups,
  remove_hidden_groups: req.removeHiddenGroups,
  protected_branch_ids: req.protectedBranchIds,
  scanners: req.scanners,
});

export const mapApprovalFallbackRuleRequest = (req) => ({
  fallback_approvals_required: req.approvalsRequired,
});

export const mapApprovalRuleResponse = (res) => ({
  id: res.id,
  hasSource: Boolean(res.source_rule),
  name: res.name,
  approvalsRequired: res.approvals_required,
  minApprovalsRequired: 0,
  approvers: res.approvers,
  containsHiddenGroups: res.contains_hidden_groups,
  users: res.users,
  groups: res.groups,
  ruleType: res.rule_type,
  protectedBranches: res.protected_branches,
  overridden: res.overridden,
  scanners: res.scanners,
});

export const mapApprovalSettingsResponse = (res) => ({
  rules: withDefaultEmptyRule(res.rules.map(mapApprovalRuleResponse)),
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

export const groupApprovalsMappers = {
  mapDataToState: (data) => ({
    preventAuthorApproval: !data.allow_author_approval,
    preventMrApprovalRuleEdit: !data.allow_overrides_to_approver_list_per_merge_request,
    requireUserPassword: data.require_password_to_approve,
    removeApprovalsOnPush: !data.retain_approvals_on_push,
    preventCommittersApproval: !data.allow_committer_approval,
  }),
  mapStateToPayload: (state) => ({
    allow_author_approval: !state.settings.preventAuthorApproval,
    allow_overrides_to_approver_list_per_merge_request: !state.settings.preventMrApprovalRuleEdit,
    require_password_to_approve: state.settings.requireUserPassword,
    retain_approvals_on_push: !state.settings.removeApprovalsOnPush,
    allow_committer_approval: !state.settings.preventCommittersApproval,
  }),
};
