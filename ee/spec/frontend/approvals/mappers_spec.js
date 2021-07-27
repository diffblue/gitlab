import { groupApprovalsMappers } from 'ee/approvals/mappers';

describe('approvals mappers', () => {
  describe('groupApprovalsMappers', () => {
    const groupPayload = {
      allow_author_approval: true,
      allow_overrides_to_approver_list_per_merge_request: true,
      require_password_to_approve: true,
      retain_approvals_on_push: true,
      allow_committer_approval: true,
    };
    const groupState = {
      settings: {
        preventAuthorApproval: false,
        preventMrApprovalRuleEdit: false,
        requireUserPassword: true,
        removeApprovalsOnPush: false,
        preventCommittersApproval: false,
      },
    };

    it('maps data to state', () => {
      expect(groupApprovalsMappers.mapDataToState(groupPayload)).toStrictEqual(groupState.settings);
    });

    it('maps state to payload', () => {
      expect(groupApprovalsMappers.mapStateToPayload(groupState)).toStrictEqual(groupPayload);
    });
  });
});
