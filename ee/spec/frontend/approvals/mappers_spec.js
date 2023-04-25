import {
  COVERAGE_CHECK_NAME,
  REPORT_TYPE_CODE_COVERAGE,
  RULE_TYPE_REPORT_APPROVER,
} from 'ee/approvals/constants';
import { mergeRequestApprovalSettingsMappers, mapApprovalRuleRequest } from 'ee/approvals/mappers';
import { createGroupApprovalsPayload, createGroupApprovalsState } from './mocks';

describe('approvals mappers', () => {
  describe('mergeRequestApprovalSettingsMappers', () => {
    const approvalsState = createGroupApprovalsState();
    const approvalsFetchPayload = createGroupApprovalsPayload();
    const approvalsUpdatePayload = {
      allow_author_approval: true,
      allow_overrides_to_approver_list_per_merge_request: true,
      require_password_to_approve: true,
      retain_approvals_on_push: false,
      selective_code_owner_removals: false,
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

  describe('mapApprovalRuleRequest', () => {
    describe.each`
      ruleName               | expectedReportType           | expectedRuleType
      ${COVERAGE_CHECK_NAME} | ${REPORT_TYPE_CODE_COVERAGE} | ${RULE_TYPE_REPORT_APPROVER}
      ${'Test Name'}         | ${undefined}                 | ${undefined}
    `('with rule name set to $ruleName', ({ ruleName, expectedRuleType, expectedReportType }) => {
      it(`it returns ${expectedRuleType} rule_type for ${ruleName}`, () => {
        expect(mapApprovalRuleRequest({ name: ruleName }).rule_type).toBe(expectedRuleType);
      });
      it(`it returns ${expectedReportType} report_type for ${ruleName}`, () => {
        expect(mapApprovalRuleRequest({ name: ruleName }).report_type).toBe(expectedReportType);
      });
    });
  });
});
