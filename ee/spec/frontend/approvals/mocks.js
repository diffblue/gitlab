export const createProjectRules = () => [
  {
    id: 1,
    name: 'Lorem',
    approvalsRequired: 2,
    approvers: [{ id: 7 }, { id: 8 }],
    ruleType: 'regular',
  },
  { id: 2, name: 'Ipsum', approvalsRequired: 0, approvers: [{ id: 9 }], ruleType: 'regular' },
  { id: 3, name: 'Dolarsit', approvalsRequired: 3, approvers: [], ruleType: 'regular' },
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
    locked: false,
    inherited_from: null,
  },
  allow_overrides_to_approver_list_per_merge_request: {
    value: true,
    locked: false,
    inherited_from: null,
  },
  retain_approvals_on_push: {
    value: true,
    locked: null,
    inherited_from: null,
  },
  require_password_to_approve: {
    value: true,
    locked: null,
    inherited_from: null,
  },
});
