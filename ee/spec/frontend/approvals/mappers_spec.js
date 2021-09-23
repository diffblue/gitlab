import { mergeRequestApprovalSettingsMappers } from 'ee/approvals/mappers';
import { createGroupApprovalsPayload, createGroupApprovalsState } from './mocks';

describe('approvals mappers', () => {
  describe('mergeRequestApprovalSettingsMappers', () => {
    const approvalsState = createGroupApprovalsState();
    const approvalsFetchPayload = createGroupApprovalsPayload();
    const approvalsUpdatePayload = {
      allow_author_approval: true,
      allow_overrides_to_approver_list_per_merge_request: true,
      require_password_to_approve: true,
      retain_approvals_on_push: true,
      allow_committer_approval: true,
    };

    it('maps data to state', () => {
      expect(
        mergeRequestApprovalSettingsMappers.mapDataToState(approvalsFetchPayload),
      ).toStrictEqual(approvalsState.settings);
    });

    it('maps state to payload', () => {
      expect(mergeRequestApprovalSettingsMappers.mapStateToPayload(approvalsState)).toStrictEqual(
        approvalsUpdatePayload,
      );
    });
  });
});
