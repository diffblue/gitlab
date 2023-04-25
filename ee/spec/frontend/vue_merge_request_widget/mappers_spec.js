import {
  RULE_TYPE_REGULAR,
  RULE_TYPE_CODE_OWNER,
  RULE_TYPE_REPORT_APPROVER,
} from 'ee/approvals/constants';
import { mapApprovalsResponse } from 'ee/vue_merge_request_widget/mappers';

describe('EE MR Widget mappers', () => {
  let data;

  beforeEach(() => {
    data = {
      approval_rules_left: [
        { name: 'Lorem', rule_type: RULE_TYPE_REGULAR },
        { name: '', rule_type: RULE_TYPE_REGULAR },
        { name: 'Ipsum', rule_type: RULE_TYPE_REGULAR },
      ],
    };
  });

  describe('mapApprovalsResponse', () => {
    describe('with multiple approval rules allowed', () => {
      beforeEach(() => {
        data.multiple_approval_rules_available = true;
      });

      it('approvalRuleNamesLeft does not include empty names', () => {
        const result = mapApprovalsResponse(data);

        expect(result).toEqual(
          expect.objectContaining({
            approvalRuleNamesLeft: ['Lorem', 'Ipsum'],
          }),
        );
      });

      it('approvalRuleNamesLeft includes report approvers', () => {
        data.approval_rules_left.push({
          name: 'Coverage-Check',
          rule_type: RULE_TYPE_REPORT_APPROVER,
        });

        const result = mapApprovalsResponse(data);

        expect(result).toMatchObject({
          approvalRuleNamesLeft: ['Lorem', 'Ipsum', 'Coverage-Check'],
        });
      });

      it('approvalRuleNamesLeft includes "Code Owners" if any', () => {
        data.approval_rules_left.push(
          { name: 'src/foo', rule_type: RULE_TYPE_CODE_OWNER },
          { name: 'src/bar', rule_type: RULE_TYPE_CODE_OWNER },
        );

        const result = mapApprovalsResponse(data);

        expect(result).toEqual(
          expect.objectContaining({
            approvalRuleNamesLeft: ['Lorem', 'Ipsum', 'Code Owners'],
          }),
        );
      });

      it('approvalRuleNamesLeft is empty with no rules left', () => {
        const result = mapApprovalsResponse({
          ...data,
          approval_rules_left: [],
        });

        expect(result).toEqual(
          expect.objectContaining({
            approvalRuleNamesLeft: [],
          }),
        );
      });
    });

    describe('with single approval rule allowed', () => {
      beforeEach(() => {
        data.multiple_approval_rules_available = false;
      });

      it('approvalRuleNamesLeft is empty', () => {
        const result = mapApprovalsResponse(data);

        expect(result).toEqual(
          expect.objectContaining({
            approvalRuleNamesLeft: [],
          }),
        );
      });
    });
  });
});
