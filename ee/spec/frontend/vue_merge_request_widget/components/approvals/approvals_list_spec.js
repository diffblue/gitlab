import Vue from 'vue';
import VueApollo from 'vue-apollo';
import approvalRulesResponse from 'test_fixtures/graphql/merge_requests/approvals/approval_rules.json';
import approvalRulesCodeownersResponse from 'test_fixtures/graphql/merge_requests/approvals/approval_rules_with_code_owner.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import approvalRulesQuery from 'ee/vue_merge_request_widget/components/approvals/queries/approval_rules.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import ApprovalsList from 'ee/vue_merge_request_widget/components/approvals/approvals_list.vue';
import ApprovedIcon from 'ee/vue_merge_request_widget/components/approvals/approved_icon.vue';
import { s__ } from '~/locale';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';
import NumberOfApprovals from 'ee/vue_merge_request_widget/components/approvals/number_of_approvals.vue';
import ApprovalsUsersList from 'ee/vue_merge_request_widget/components/approvals/approvals_users_list.vue';

Vue.use(VueApollo);

describe('EE MRWidget approvals list', () => {
  let wrapper;

  const createComponent = (response = approvalRulesResponse) => {
    wrapper = shallowMountExtended(ApprovalsList, {
      propsData: {
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

      it('does not render eligible approvers list when there are none', () => {
        const rowWithoutEligibleApprovers = wrapper.findAllByTestId('approval-rules-row').at(0);
        const approvers = rowWithoutEligibleApprovers.findAllComponents(UserAvatarList);

        expect(approvers).toHaveLength(2);
      });

      it('renders eligible approvers list if any', () => {
        const rowWithEligibleApprovers = wrapper.findAllByTestId('approval-rules-row').at(1);
        const approvers = rowWithEligibleApprovers.findAllComponents(UserAvatarList);

        expect(approvers).toHaveLength(4);
        expect(approvers.at(0).exists()).toBe(true);
        expect(approvers.at(0).props()).toEqual(
          expect.objectContaining({
            items: rule.eligibleApprovers,
          }),
        );
      });

      it('renders commented by list', () => {
        const commentedBy = summary.findAllComponents(ApprovalsUsersList).at(0);

        expect(commentedBy.props()).toEqual({
          label: s__('MRApprovals|Commented by'),
          users: rule.commentedBy.nodes,
        });
      });

      it('renders approved by list', () => {
        const approvedBy = summary.findAllComponents(ApprovalsUsersList).at(1);

        expect(approvedBy.props()).toEqual({
          label: s__('MRApprovals|Approved by'),
          users: rule.approvedBy.nodes,
        });
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
