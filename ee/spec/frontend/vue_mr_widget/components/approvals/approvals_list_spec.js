import { shallowMount } from '@vue/test-utils';
import ApprovalsList from 'ee/vue_merge_request_widget/components/approvals/approvals_list.vue';
import ApprovedIcon from 'ee/vue_merge_request_widget/components/approvals/approved_icon.vue';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';
import NumberOfApprovals from 'ee/vue_merge_request_widget/components/approvals/number_of_approvals.vue';

const testApprovers = () => Array.from({ length: 11 }, (_, i) => i).map((id) => ({ id }));
const testRuleApproved = () => ({
  id: 1,
  name: 'Lorem',
  approvals_required: 2,
  approved_by: [{ id: 1 }, { id: 2 }, { id: 3 }],
  commented_by: [{ id: 1 }, { id: 2 }, { id: 3 }],
  approvers: testApprovers(),
  approved: true,
});
const testRuleUnapproved = () => ({
  id: 2,
  name: 'Ipsum',
  approvals_required: 1,
  approved_by: [],
  commented_by: [],
  approvers: testApprovers(),
  approved: false,
});
const testRuleOptional = () => ({
  id: 3,
  name: 'Dolar',
  approvals_required: 0,
  approved_by: [{ id: 1 }],
  commented_by: [{ id: 1 }],
  approvers: testApprovers(),
  approved: false,
});
const testRuleFallback = () => ({
  id: 'fallback',
  name: '',
  fallback: true,
  rule_type: 'any_approver',
  approvals_required: 3,
  approved_by: [{ id: 1 }, { id: 2 }],
  commented_by: [{ id: 1 }, { id: 2 }],
  approvers: [],
  approved: false,
});
const testRuleCodeOwner = () => ({
  id: '*.js',
  name: '*.js',
  fallback: true,
  approvals_required: 3,
  approved_by: [{ id: 1 }, { id: 2 }],
  commented_by: [{ id: 1 }, { id: 2 }],
  approvers: [],
  approved: false,
  rule_type: 'code_owner',
  section: 'Frontend',
});
const testRules = () => [testRuleApproved(), testRuleUnapproved(), testRuleOptional()];
const testInvalidRules = () => testRules().slice(0, 1);

describe('EE MRWidget approvals list', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(ApprovalsList, {
      propsData: { invalidApproversRules: testInvalidRules(), ...props },
    });
  };

  const findRows = () => wrapper.findAll('tbody tr');
  const findRowElement = (row, name) => row.find(`.js-${name}`);
  const findRowIcon = (row) => row.findComponent(ApprovedIcon);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when multiple rules', () => {
    beforeEach(() => {
      createComponent({
        approvalRules: testRules(),
      });
    });

    it('renders a row for each rule', () => {
      const expected = testRules();
      const rows = findRows();
      const names = rows.wrappers.map((row) => findRowElement(row, 'name').text());

      expect(rows).toHaveLength(expected.length);
      expect(names).toEqual(expected.map((x) => x.name));
    });

    it('does not render a code owner subtitle', () => {
      expect(wrapper.find('.js-section-title').exists()).toBe(false);
    });

    describe('when a code owner rule is included', () => {
      let rulesWithCodeOwner;

      beforeEach(() => {
        rulesWithCodeOwner = testRules().concat([testRuleCodeOwner()]);
        createComponent({
          approvalRules: rulesWithCodeOwner,
        });
      });

      it('renders a code owner subtitle', () => {
        const rows = findRows();

        expect(wrapper.find('.js-section-title').exists()).toBe(true);
        expect(rows).toHaveLength(rulesWithCodeOwner.length + 1);
      });
    });
  });

  describe('when approved rule', () => {
    const rule = testRuleApproved();
    let row;

    beforeEach(() => {
      createComponent({
        approvalRules: [rule],
      });
      row = findRows().at(0);
    });

    it('renders approved icon', () => {
      const icon = findRowIcon(row);

      expect(icon.exists()).toBe(true);
      expect(icon.props()).toEqual(
        expect.objectContaining({
          isApproved: true,
        }),
      );
    });

    it('renders name', () => {
      expect(findRowElement(row, 'name').text()).toEqual(rule.name);
    });

    it('renders approvers', () => {
      const approversCell = findRowElement(row, 'approvers');
      const approvers = approversCell.findComponent(UserAvatarList);

      expect(approvers.exists()).toBe(true);
      expect(approvers.props()).toEqual(
        expect.objectContaining({
          items: testApprovers(),
        }),
      );
    });

    it('renders pending object (instance of NumberOfApprovals)', () => {
      const pendingObject = findRowElement(row, 'pending');
      const numberOfApprovals = pendingObject.find(NumberOfApprovals);

      expect(numberOfApprovals.exists()).toBe(true);
      expect(numberOfApprovals.props('invalidApproversRules')).toEqual(testInvalidRules());
    });

    it('renders approved_by user avatar list', () => {
      const approvedBy = findRowElement(row, 'approved-by');
      const approvers = approvedBy.findComponent(UserAvatarList);

      expect(approvers.exists()).toBe(true);
      expect(approvers.props()).toEqual(
        expect.objectContaining({
          items: rule.approved_by,
          emptyText: '',
        }),
      );
    });

    it('renders commented by user avatar list', () => {
      const commentedRow = findRowElement(row, 'commented-by');
      const commentedBy = commentedRow.findComponent(UserAvatarList);

      expect(commentedBy.props()).toEqual(
        expect.objectContaining({
          items: rule.commented_by,
          emptyText: '',
        }),
      );
    });

    describe('summary text', () => {
      let summary;

      beforeEach(() => {
        summary = findRowElement(row, 'summary');
      });

      it('renders text', () => {
        const count = rule.approved_by.length;
        const required = rule.approvals_required;
        const { name } = rule;

        expect(summary.text()).toContain(`${count} of ${required} approvals from ${name}`);
      });

      it('renders approvers list', () => {
        const approvers = summary.findAllComponents(UserAvatarList).at(0);

        expect(approvers.exists()).toBe(true);
        expect(approvers.props()).toEqual(
          expect.objectContaining({
            items: rule.approvers,
          }),
        );
      });

      it('renders commented by list', () => {
        const commentedBy = summary.findAllComponents(UserAvatarList).at(1);

        expect(commentedBy.props()).toEqual(
          expect.objectContaining({
            items: rule.commented_by,
          }),
        );
      });

      it('renders approved by list', () => {
        const approvedBy = summary.findAllComponents(UserAvatarList).at(2);

        expect(approvedBy.props()).toEqual(
          expect.objectContaining({
            items: rule.approved_by,
          }),
        );
      });
    });
  });

  describe('when unapproved rule', () => {
    const rule = testRuleUnapproved();
    let row;

    beforeEach(() => {
      createComponent({
        approvalRules: [rule],
      });
      row = findRows().at(0);
    });

    it('renders unapproved icon', () => {
      const icon = findRowIcon(row);

      expect(icon.exists()).toBe(true);
      expect(icon.props()).toEqual(
        expect.objectContaining({
          isApproved: false,
        }),
      );
    });
  });

  describe('when optional rule', () => {
    const rule = testRuleOptional();
    let row;

    beforeEach(() => {
      createComponent({
        approvalRules: [rule],
      });
      row = findRows().at(0);
    });

    it('renders unapproved icon', () => {
      const icon = findRowIcon(row);

      expect(icon.exists()).toBe(true);
      expect(icon.props()).toEqual(
        expect.objectContaining({
          isApproved: false,
        }),
      );
    });

    it('renders pending object (instance of NumberOfApprovals)', () => {
      const pendingObject = findRowElement(row, 'pending');

      expect(pendingObject.find(NumberOfApprovals).exists()).toBe(true);
    });

    it('renders optional summary text', () => {
      const summary = findRowElement(row, 'summary');

      expect(summary.text()).toContain(`${rule.approved_by.length} approvals from ${rule.name}`);
    });
  });

  describe('when fallback rule', () => {
    const rule = testRuleFallback();
    let row;

    beforeEach(() => {
      createComponent({
        approvalRules: [rule],
      });
      row = findRows().at(0);
    });

    it('does not render approvers', () => {
      expect(findRowElement(row, 'approvers').exists()).toBe(false);
    });

    it('does not render approvers in summary', () => {
      const summary = findRowElement(row, 'summary');
      const lists = summary.findAllComponents(UserAvatarList);

      expect(lists).toHaveLength(2);
      expect(lists.at(0).props('items')).toEqual(rule.commented_by);
      expect(lists.at(1).props('items')).toEqual(rule.approved_by);
    });
  });

  describe('when code owner rule', () => {
    const rule = testRuleCodeOwner();
    const ruleDefaultCodeOwners = {
      ...testRuleCodeOwner(),
      id: 2,
      section: 'codeowners',
    };
    const ruleDocsSection = {
      ...testRuleCodeOwner(),
      id: 1,
      section: 'Docs',
    };
    let row;

    beforeEach(() => {
      createComponent({
        approvalRules: [rule, ruleDefaultCodeOwners, ruleDocsSection],
      });
      row = findRows().at(1);
    });

    it('renders the code owner title row', () => {
      const titleRow = findRows().at(0);

      expect(titleRow.text()).toEqual('Code Owners');
    });

    it('renders the name in a monospace font', () => {
      const codeOwnerRow = findRowElement(row, 'name');

      expect(codeOwnerRow.find('.gl-font-monospace').exists()).toEqual(true);
      expect(codeOwnerRow.text()).toContain(rule.name);
    });

    it('renders code owner section name', () => {
      const ruleSection = wrapper.findAll('[data-testid="rule-section"]');

      expect(ruleSection.at(0).text()).toEqual(ruleDocsSection.section);
      expect(ruleSection.at(1).text()).toEqual(rule.section);
    });
  });
});
