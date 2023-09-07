import { groupBy } from 'lodash';
import {
  RULE_TYPE_REGULAR,
  RULE_TYPE_FALLBACK,
  RULE_TYPE_CODE_OWNER,
  RULE_TYPE_REPORT_APPROVER,
  RULE_TYPE_ANY_APPROVER,
} from 'ee/approvals/constants';
import { __ } from '~/locale';

function mapApprovalRule(rule, settings) {
  if (rule.rule_type === RULE_TYPE_FALLBACK) {
    // Show a friendly name for the fallback rule
    return {
      ...rule,
      name: __('All Members'),
      fallback: true,
    };
  }
  if (rule.rule_type === RULE_TYPE_REGULAR && !settings.multiple_approval_rules_available) {
    // Give a friendly name to the single rule
    return {
      ...rule,
      name: __('Merge Request'),
    };
  }

  return rule;
}

export function getApprovalRuleNamesLeft(multipleApprovalRulesAvailable, rules) {
  if (!multipleApprovalRulesAvailable) {
    return [];
  }

  const rulesLeft = groupBy(rules, (x) => x.rule_type || x.type?.toLowerCase());

  const anyApprover = rulesLeft[RULE_TYPE_ANY_APPROVER] ? [__('eligible users')] : [];

  // Filter out empty names (fallback rule has no name) because the empties would look weird.
  const regularRules = (rulesLeft[RULE_TYPE_REGULAR] || []).map((x) => x.name).filter((x) => x);

  // Report Approvals
  const reportApprovalRules = (rulesLeft[RULE_TYPE_REPORT_APPROVER] || []).map((x) => x.name);

  // If there are code owners that need to approve, only mention that once.
  // As the names of code owner rules are patterns that don't mean much out of context.
  const codeOwnerRules = rulesLeft[RULE_TYPE_CODE_OWNER] ? [__('Code Owners')] : [];

  return [...anyApprover, ...regularRules, ...reportApprovalRules, ...codeOwnerRules];
}

/**
 * Map the approval rules response for use by the MR widget
 */
export function mapApprovalRulesResponse(rules, settings) {
  return rules.map((x) => mapApprovalRule(x, settings));
}

/**
 * Map the overall approvals response for use by the MR widget
 */
export function mapApprovalsResponse(data) {
  return {
    ...data,
    approvalRuleNamesLeft: getApprovalRuleNamesLeft(
      data.multiple_approval_rules_available,
      data.approval_rules_left,
    ),
  };
}
