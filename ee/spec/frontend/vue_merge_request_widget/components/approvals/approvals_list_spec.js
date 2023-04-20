import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import approvalRulesResponse from 'test_fixtures/graphql/merge_requests/approvals/approval_rules.json';
import approvalRulesCodeownersResponse from 'test_fixtures/graphql/merge_requests/approvals/approval_rules_with_code_owner.json';
import waitForPromises from 'helpers/wait_for_promises';
import approvalRulesQuery from 'ee/vue_merge_request_widget/components/approvals/queries/approval_rules.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import ApprovalsList from 'ee/vue_merge_request_widget/components/approvals/approvals_list.vue';
import ApprovedIcon from 'ee/vue_merge_request_widget/components/approvals/approved_icon.vue';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';
import NumberOfApprovals from 'ee/vue_merge_request_widget/components/approvals/number_of_approvals.vue';

Vue.use(VueApollo);

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
const testRules = () => [testRuleApproved(), testRuleUnapproved(), testRuleOptional()];
const testInvalidRules = () => testRules().slice(0, 1);

describe('EE MRWidget approvals list', () => {
  let wrapper;

  const createComponent = (response = approvalRulesResponse) => {
    wrapper = shallowMount(ApprovalsList, {
      propsData: {
        invalidApproversRules: testInvalidRules(),
        projectPath: 'gitlab-org/gitlab',
        iid: '1',
      },
      apolloProvider: createMockApollo([
        [approvalRulesQuery, jest.fn().mockResolvedValue(response)],
      ]),
    });
  };

  const findRows = () => wrapper.findAll('tbody tr');
  const findRowElement = (row, name) => row.find(`.js-${name}`);
  const findRowIcon = (row) => row.findComponent(ApprovedIcon);

  describe('when multiple rules', () => {
    beforeEach(async () => {
      createComponent();

      await waitForPromises();
    });

    it('renders a row for each rule', () => {
      const rows = findRows();
      const expected = approvalRulesResponse.data.project.mergeRequest.approvalState.rules;

      expect(rows).toHaveLength(expected.length);
    });

    it('does not render a code owner subtitle', () => {
      expect(wrapper.find('.js-section-title').exists()).toBe(false);
    });

    describe('when a code owner rule is included', () => {
      beforeEach(async () => {
        wrapper.destroy();
        createComponent(approvalRulesCodeownersResponse);

        await waitForPromises();
      });

      it('renders a code owner subtitle', () => {
        expect(wrapper.find('.js-section-title').exists()).toBe(true);
      });
    });
  });

  describe('when approved rule', () => {
    let rule;
    let row;

    beforeEach(async () => {
      createComponent();

      await waitForPromises();

      row = findRows().at(1);
      // eslint-disable-next-line prefer-destructuring
      rule = approvalRulesResponse.data.project.mergeRequest.approvalState.rules[1];
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
          items: rule.eligibleApprovers,
        }),
      );
    });

    it('renders pending object (instance of NumberOfApprovals)', () => {
      const pendingObject = findRowElement(row, 'pending');
      const numberOfApprovals = pendingObject.findComponent(NumberOfApprovals);

      expect(numberOfApprovals.exists()).toBe(true);
      expect(numberOfApprovals.props('invalidApproversRules')).toEqual(testInvalidRules());
    });

    it('renders approved_by user avatar list', () => {
      const approvedBy = findRowElement(row, 'approved-by');
      const approvers = approvedBy.findComponent(UserAvatarList);

      expect(approvers.exists()).toBe(true);
      expect(approvers.props()).toEqual(
        expect.objectContaining({
          items: rule.approvedBy.nodes,
          emptyText: '',
        }),
      );
    });

    it('renders commented by user avatar list', () => {
      const commentedRow = findRowElement(row, 'commented-by');
      const commentedBy = commentedRow.findComponent(UserAvatarList);

      expect(commentedBy.props()).toEqual(
        expect.objectContaining({
          items: rule.commentedBy.nodes,
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
        const count = rule.approvedBy.nodes.length;
        const required = rule.approvalsRequired;
        const { name } = rule;

        expect(summary.text()).toContain(`${count} of ${required} approvals from ${name}`);
      });

      it('renders approvers list', () => {
        const approvers = summary.findAllComponents(UserAvatarList).at(0);

        expect(approvers.exists()).toBe(true);
        expect(approvers.props()).toEqual(
          expect.objectContaining({
            items: rule.eligibleApprovers,
          }),
        );
      });

      it('renders commented by list', () => {
        const commentedBy = summary.findAllComponents(UserAvatarList).at(1);

        expect(commentedBy.props()).toEqual(
          expect.objectContaining({
            items: rule.commentedBy.nodes,
          }),
        );
      });

      it('renders approved by list', () => {
        const approvedBy = summary.findAllComponents(UserAvatarList).at(2);

        expect(approvedBy.props()).toEqual(
          expect.objectContaining({
            items: rule.approvedBy.nodes,
          }),
        );
      });
    });
  });

  describe('when unapproved rule', () => {
    let row;

    beforeEach(async () => {
      createComponent();

      await waitForPromises();

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
    let row;

    beforeEach(async () => {
      createComponent();

      await waitForPromises();

      row = findRows().at(0);
    });

    it('renders pending object (instance of NumberOfApprovals)', () => {
      const pendingObject = findRowElement(row, 'pending');

      expect(pendingObject.findComponent(NumberOfApprovals).exists()).toBe(true);
    });
  });

  describe('when code owner rule', () => {
    let row;

    beforeEach(async () => {
      createComponent(approvalRulesCodeownersResponse);

      await waitForPromises();

      row = findRows().at(5);
    });

    it('renders the code owner title row', () => {
      expect(findRows().at(4).text()).toEqual('Code Owners');
    });

    it('renders the name in a monospace font', () => {
      const codeOwnerRow = findRowElement(row, 'name');

      expect(codeOwnerRow.find('.gl-font-monospace').exists()).toEqual(true);
      expect(codeOwnerRow.text()).toContain('*.js');
    });

    it('renders code owner section name', () => {
      const ruleSection = wrapper.findAll('[data-testid="rule-section"]');

      expect(ruleSection.at(0).text()).toEqual('Frontend');
    });
  });
});
