export const createProjectRules = () => [
  {
    id: 1,
    name: 'Lorem',
    approvalsRequired: 2,
    eligibleApprovers: [{ id: 7 }, { id: 8 }],
    ruleType: 'regular',
  },
  {
    id: 2,
    name: 'Ipsum',
    approvalsRequired: 0,
    eligibleApprovers: [{ id: 9 }],
    ruleType: 'regular',
  },
  { id: 3, name: 'Dolarsit', approvalsRequired: 3, eligibleApprovers: [], ruleType: 'regular' },
];

export const createMRRule = () => ({
  id: 7,
  name: 'Amit',
  approvers: [{ id: 1 }, { id: 2 }],
  approvalsRequired: 2,
  minApprovalsRequired: 0,
  ruleType: 'regular',
});

export const createEmptyRule = () => ({
  id: 5,
  name: 'All Members',
  approvers: [],
  approvalsRequired: 3,
  minApprovalsRequired: 0,
  ruleType: 'any_approver',
});

export const createMRRuleWithSource = () => ({
  ...createEmptyRule(),
  ...createMRRule(),
  minApprovalsRequired: 1,
  hasSource: true,
  sourceId: 3,
});

export const createGroupApprovalsPayload = () => ({
  allow_author_approval: {
    value: true,
    locked: true,
    inherited_from: 'instance',
  },
  allow_committer_approval: {
    value: true,
    locked: true,
    inherited_from: 'group',
  },
  allow_overrides_to_approver_list_per_merge_request: {
    value: true,
    locked: false,
    inherited_from: null,
  },
  retain_approvals_on_push: {
    value: false,
    locked: null,
    inherited_from: null,
  },
  selective_code_owner_removals: {
    value: false,
    locked: null,
    inheritedFrom: null,
  },
  require_password_to_approve: {
    value: true,
    locked: null,
    inherited_from: null,
  },
});

export const createGroupApprovalsState = (locked = null) => ({
  settings: {
    preventAuthorApproval: {
      inheritedFrom: 'instance',
      locked: locked ?? true,
      value: false,
    },
    preventCommittersApproval: {
      inheritedFrom: 'group',
      locked: locked ?? true,
      value: false,
    },
    preventMrApprovalRuleEdit: {
      inheritedFrom: null,
      locked: locked ?? false,
      value: false,
    },
    removeApprovalsOnPush: {
      inheritedFrom: null,
      locked,
      value: true,
    },
    selectiveCodeOwnerRemovals: {
      inheritedFrom: null,
      locked,
      value: false,
    },
    requireUserPassword: {
      inheritedFrom: null,
      locked,
      value: true,
    },
  },
});

export const TEST_PROTECTED_BRANCHES = [{ id: 2 }, { id: 3 }, { id: 4 }];

export const TEST_RULE = {
  id: 10,
  name: 'QA',
  approvalsRequired: 2,
  users: [{ id: 1 }, { id: 2 }, { id: 3 }],
  groups: [{ id: 1 }, { id: 2 }],
};

export const TEST_RULE_WITH_PROTECTED_BRANCHES = {
  ...TEST_RULE,
  protectedBranches: TEST_PROTECTED_BRANCHES,
};

export const TEST_RULE_WITH_ALL_BRANCHES = {
  ...TEST_RULE,
  protectedBranches: [],
};

export const TEST_RULE_WITH_ALL_PROTECTED_BRANCHES = {
  ...TEST_RULE,
  protectedBranches: TEST_PROTECTED_BRANCHES,
  appliesToAllProtectedBranches: true,
};
