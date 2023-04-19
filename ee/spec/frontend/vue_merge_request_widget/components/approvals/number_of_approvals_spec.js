import { shallowMount } from '@vue/test-utils';
import NumberOfApprovals from 'ee/vue_merge_request_widget/components/approvals/number_of_approvals.vue';

describe('EE Number of approvals', () => {
  let wrapper;

  const rule = { approvalsRequired: 1, approvedBy: { nodes: [] }, id: 1, name: 'rule-name' };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(NumberOfApprovals, {
      propsData: { rule, ...props },
    });
  };

  const findAutoApprovedPopover = () => wrapper.find("[data-testid='popover-auto-approved']");
  const findActionRequiredPopover = () => wrapper.find("[data-testid='popover-action-required']");
  const findApprovalText = () => wrapper.find("[data-testid='approvals-text']");

  beforeEach(() => {
    createComponent();
  });

  describe('default', () => {
    it('renders components', () => {
      expect(findApprovalText().exists()).toBe(true);
      expect(findAutoApprovedPopover().exists()).toBe(false);
      expect(findActionRequiredPopover().exists()).toBe(false);
    });

    it('renders total number of approvals', () => {
      expect(findApprovalText().text()).toBe('0 of 1');
    });
  });

  describe('with approvals required set to zero', () => {
    beforeEach(() => {
      createComponent({ rule: { ...rule, approvalsRequired: 0 } });
    });

    it('renders optional text', () => {
      expect(findApprovalText().text()).toBe('Optional');
    });

    it('does not render popover', () => {
      expect(findAutoApprovedPopover().exists()).toBe(false);
    });
  });

  describe('with invalid rules', () => {
    const invalidRule = { ...rule, invalid: true };

    describe('with auto-approved rule', () => {
      beforeEach(() => {
        createComponent({ rule: { ...invalidRule, allowMergeWhenInvalid: true } });
      });

      it('renders auto approved text', () => {
        expect(findApprovalText().text()).toBe('Auto approved');
      });

      it('renders a correct popover', () => {
        expect(findAutoApprovedPopover().exists()).toBe(true);
      });
    });

    describe('with rule requiring action', () => {
      beforeEach(() => {
        createComponent({ rule: { ...invalidRule, allowMergeWhenInvalid: false } });
      });

      it('renders action required text', () => {
        expect(findApprovalText().text()).toBe('Action required');
      });

      it('renders a correct popover', () => {
        expect(findActionRequiredPopover().exists()).toBe(true);
      });
    });
  });
});
