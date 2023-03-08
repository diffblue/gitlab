import { GlPopover } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import NumberOfApprovals from 'ee/vue_merge_request_widget/components/approvals/number_of_approvals.vue';

describe('EE Number of approvals', () => {
  let wrapper;

  const rule = { approvalsRequired: 1, approvedBy: { nodes: [] }, id: 1, name: 'rule-name' };
  const invalidApproversRules = [];

  const createComponent = (props = {}) => {
    wrapper = shallowMount(NumberOfApprovals, {
      propsData: { rule, invalidApproversRules, ...props },
    });
  };

  const findApprovalCheckPopover = () => wrapper.findComponent(GlPopover);
  const findApprovalText = () => wrapper.find("[data-testid='approvals-text']");

  beforeEach(() => {
    createComponent();
  });

  describe('default', () => {
    it('renders components', () => {
      expect(findApprovalText().exists()).toBe(true);
      expect(findApprovalCheckPopover().exists()).toBe(false);
    });

    it('renders total number of approvals', () => {
      expect(findApprovalText().text()).toBe('0 of 1');
    });
  });

  describe('with approvals required set to zero', () => {
    beforeEach(() => {
      createComponent({ rule: { rule, approvalsRequired: 0 } });
    });

    it('renders optional text', () => {
      expect(findApprovalText().text()).toBe('Optional');
    });

    it('does not render popover', () => {
      expect(findApprovalCheckPopover().exists()).toBe(false);
    });
  });

  describe('with invalid rules', () => {
    beforeEach(() => {
      createComponent({ invalidApproversRules: [rule] });
    });

    it('renders invalid text', () => {
      expect(findApprovalText().text()).toBe('Invalid');
    });

    it('renders popover', () => {
      expect(findApprovalCheckPopover().exists()).toBe(true);
    });
  });
});
