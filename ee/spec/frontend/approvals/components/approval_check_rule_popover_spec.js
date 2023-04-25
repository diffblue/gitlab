import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import ApprovalCheckRulePopover from 'ee/approvals/components/approval_check_rule_popover.vue';
import ApprovalCheckPopover from 'ee/approvals/components/approval_check_popover.vue';
import { COVERAGE_CHECK_NAME, APPROVAL_RULE_CONFIGS } from 'ee/approvals/constants';
import { TEST_HOST } from 'helpers/test_constants';

describe('Approval Check Popover', () => {
  let wrapper;
  const codeCoverageCheckHelpPagePath = `${TEST_HOST}/documentation`;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(ApprovalCheckRulePopover, {
      propsData: { rule: {}, codeCoverageCheckHelpPagePath, ...props },
    });
  };

  const findApprovalCheckPopover = () => wrapper.findComponent(ApprovalCheckPopover);

  describe('computed props', () => {
    describe('showCoverageCheckPopover', () => {
      it('return true if the rule type is "Coverage-Check"', async () => {
        createComponent({ rule: { name: COVERAGE_CHECK_NAME } });
        await nextTick();
        expect(findApprovalCheckPopover().exists()).toBe(true);
      });

      it('return false if the rule type is "Coverage-Check"', async () => {
        createComponent({ rule: { name: 'FooRule' } });
        await nextTick();
        expect(findApprovalCheckPopover().exists()).toBe(false);
      });
    });

    describe('approvalConfig', () => {
      it('returns "Coverage-Check" config', async () => {
        createComponent({ rule: { name: COVERAGE_CHECK_NAME } });
        await nextTick();
        expect(findApprovalCheckPopover().props('title')).toBe(
          APPROVAL_RULE_CONFIGS[COVERAGE_CHECK_NAME].title,
        );
        expect(findApprovalCheckPopover().props('text')).toBe(
          APPROVAL_RULE_CONFIGS[COVERAGE_CHECK_NAME].popoverText,
        );
        expect(findApprovalCheckPopover().props('documentationText')).toBe(
          APPROVAL_RULE_CONFIGS[COVERAGE_CHECK_NAME].documentationText,
        );
      });
    });

    describe('documentationLink', () => {
      it('returns documentation link for "Coverage-Check"', async () => {
        createComponent({ rule: { name: COVERAGE_CHECK_NAME } });
        await nextTick();
        expect(findApprovalCheckPopover().props('documentationLink')).toBe(
          codeCoverageCheckHelpPagePath,
        );
      });
    });

    describe('popoverTriggerId', () => {
      it('returns popover id', async () => {
        createComponent({ rule: { name: COVERAGE_CHECK_NAME } });
        await nextTick();
        const expectedPopoverTriggerId = 'reportInfo-Coverage-Check';
        expect(findApprovalCheckPopover().props('popoverId')).toBe(expectedPopoverTriggerId);
      });
    });
  });
});
