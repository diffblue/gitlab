# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApprovalRules::CreateService do
  let(:project) { create(:project) }
  let(:user) { project.creator }

  shared_examples 'creatable' do
    let(:new_approvers) { create_list(:user, 2) }
    let(:new_groups) { create_list(:group, 2, :private) }

    context 'basic creation action' do
      let(:result) do
        described_class.new(target, user, {
          name: 'security',
          approvals_required: 1,
          user_ids: new_approvers.map(&:id),
          group_ids: new_groups.map(&:id)
        }).execute
      end

      it 'creates approval, excluding non-eligible users and groups' do
        expect(result[:status]).to eq(:success)

        rule = result[:rule]

        expect(rule.name).to eq('security')
        expect(rule.approvals_required).to eq(1)
        expect(rule.users).to be_empty
        expect(rule.groups).to be_empty
      end

      it 'tracks creation event via a usage counter' do
        expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter)
          .to receive(:track_approval_rule_added_action).once.with(user: user)

        result
      end
    end

    context 'when some users and groups are eligible' do
      before do
        project.add_reporter new_approvers.first
        new_groups.first.add_guest(user)
      end

      it 'creates and includes eligible users and groups' do
        result = described_class.new(target, user, {
          name: 'security',
          approvals_required: 1,
          user_ids: new_approvers.map(&:id),
          group_ids: new_groups.map(&:id)
        }).execute

        expect(result[:status]).to eq(:success)

        rule = result[:rule]

        expect(rule.name).to eq('security')
        expect(rule.approvals_required).to eq(1)
        expect(rule.users).to contain_exactly(new_approvers.first)
        expect(rule.groups).to contain_exactly(new_groups.first)
      end
    end

    context 'when group is a subgroup with indirect permissions' do
      let(:subgroup) { create(:group, :private, parent: new_groups.first) }

      before do
        new_groups.first.add_guest(user)
      end

      it 'creates and includes eligible groups and subgroups' do
        result = described_class.new(target, user, {
          name: 'security',
          approvals_required: 1,
          group_ids: new_groups.map(&:id) + [subgroup.id]
        }).execute

        expect(result[:status]).to eq(:success)

        rule = result[:rule]

        expect(rule.name).to eq('security')
        expect(rule.approvals_required).to eq(1)
        expect(rule.groups).to contain_exactly(new_groups.first, subgroup)
      end
    end

    context 'when validation fails' do
      it 'returns error message' do
        result = described_class.new(target, user, {
          name: nil,
          approvals_required: 1
        }).execute

        expect(result[:status]).to eq(:error)
      end

      it_behaves_like 'does not record an onboarding progress action' do
        subject do
          described_class.new(target, user, {
            name: nil,
            approvals_required: 1
          }).execute
        end
      end
    end

    context 'when user does not have right to admin project' do
      let(:user) { create(:user) }

      it 'returns error message' do
        result = described_class.new(target, user, {
          approvals_required: 1
        }).execute

        expect(result[:status]).to eq(:error)
        expect(result[:message]).to include('Prohibited')
      end

      context 'but skip_authorization is true' do
        it 'does not return error message' do
          result = described_class.new(target, user, {
            approvals_required: 1,
            skip_authorization: true
          }).execute

          expect(result[:status]).to eq(:success)
        end
      end
    end

    # Possible when policy configuration last commit user email is not present in GitLab.
    # See: https://gitlab.com/gitlab-org/gitlab/-/issues/402173#note_1348667122
    context 'when user is not present in GitLab' do
      let_it_be(:non_existing_user) { nil }
      let_it_be(:name) { 'security' }

      let(:result) do
        described_class.new(target, non_existing_user, {
          name: name,
          skip_authorization: true,
          approvals_required: 1,
          user_ids: new_approvers.map(&:id).append(user.id),
          group_ids: new_groups.map(&:id)
        }).execute
      end

      it 'creates approval, excluding non-eligible users and groups', :aggregate_failures do
        expect(result[:status]).to eq(:success)

        rule = result[:rule]

        expect(rule.name).to eq('security')
        expect(rule.approvals_required).to eq(1)
        expect(rule.users).to match_array([user])
        expect(rule.groups).to be_empty
      end

      it 'creates approval without audit' do
        expect(::Gitlab::Audit::Auditor).not_to receive(:audit)

        expect(result[:status]).to eq(:success)
      end

      context 'validation failure' do
        let_it_be(:name) { nil }

        it 'returns error message' do
          expect(result[:status]).to eq(:error)
          expect(result[:message][:name].first).to eq("can't be blank")
        end
      end
    end

    context 'when approval rule with empty users and groups is being created' do
      subject { described_class.new(target, user, { user_ids: [], group_ids: [] }) }

      it 'sets default attributes for any-approver rule' do
        rule = subject.execute[:rule]

        expect(rule[:rule_type]).to eq('any_approver')
        expect(rule[:name]).to eq('All Members')
      end
    end

    context 'when any-approver rule exists' do
      before do
        target.approval_rules.create!(rule_type: :any_approver, name: 'All members')
      end

      context 'multiple approval rules are not enabled' do
        subject { described_class.new(target, user, { user_ids: [1], group_ids: [] }) }

        it 'removes the rule if a regular one is created' do
          expect { subject.execute }.to change(
            target.approval_rules.any_approver, :count
          ).from(1).to(0)
        end
      end

      context 'multiple approval rules are enabled' do
        subject { described_class.new(target, user, { user_ids: [1], group_ids: [] }) }

        before do
          stub_licensed_features(multiple_approval_rules: true)
        end

        it 'does not remove any approval rule' do
          expect { subject.execute }.not_to change(target.approval_rules.any_approver, :count)
        end
      end

      it_behaves_like 'records an onboarding progress action', :required_mr_approvals_enabled do
        let(:namespace) { project.namespace }

        subject do
          described_class.new(target, user, {
            name: 'security',
            approvals_required: 1,
            user_ids: new_approvers.map(&:id),
            group_ids: new_groups.map(&:id)
          }).execute
        end
      end
    end
  end

  context 'when target is project' do
    let(:target) { project }

    it_behaves_like "creatable"

    context 'when protected_branch_ids param is present' do
      let(:protected_branch) { create(:protected_branch, project: target) }
      let(:skip_authorization) { false }
      let(:protected_branch_ids) { [protected_branch.id] }

      subject do
        described_class.new(
          target,
          user,
          name: 'developers',
          approvals_required: 1,
          skip_authorization: skip_authorization,
          protected_branch_ids: protected_branch_ids
        ).execute
      end

      context 'and multiple approval rules is enabled' do
        before do
          stub_licensed_features(multiple_approval_rules: true)
        end

        it 'associates the approval rule to the protected branch' do
          expect(subject[:status]).to eq(:success)
          expect(subject[:rule].protected_branches).to eq([protected_branch])
        end

        context 'but user cannot administer project' do
          before do
            allow(Ability).to receive(:allowed?).and_call_original
            allow(Ability).to receive(:allowed?).with(user, :admin_project, target).and_return(false)
          end

          it 'does not associate the approval rule to the protected branch' do
            expect(subject[:status]).to eq(:success)
            expect(subject[:rule].protected_branches).to be_empty
          end
        end

        context 'but skip_authorization param is true' do
          let(:skip_authorization) { true }

          before do
            allow(Ability).to receive(:allowed?).and_call_original
            allow(Ability).to receive(:allowed?).with(user, :admin_project, target).and_return(false)
          end

          it 'associates the approval rule to the protected branch' do
            expect(subject[:status]).to eq(:success)
            expect(subject[:rule].protected_branches).to match_array([protected_branch])
          end
        end

        context 'but protected branch is for another project' do
          let(:another_project) { create(:project) }
          let(:protected_branch) { create(:protected_branch, project: another_project) }

          it 'does not associate the approval rule to the protected branch' do
            expect(subject[:status]).to eq(:success)
            expect(subject[:rule].protected_branches).to be_empty
          end
        end

        context 'when feature `group_protected_branches` enabled' do
          before do
            stub_feature_flags(group_protected_branches: true)
            stub_feature_flags(allow_protected_branches_for_group: true)
          end

          context 'when the root_namespace of project is not a group' do
            it 'associates the approval rule to the protected branch' do
              expect(subject[:status]).to eq(:success)
              expect(subject[:rule].protected_branches).to match_array([protected_branch])
            end
          end

          context 'when the root_namespace of project is a group' do
            let_it_be(:group) { create(:group) }
            let_it_be(:project) { create(:project, group: group) }
            let_it_be(:group_protected_branch) { create(:protected_branch, project: nil, group: group) }
            let_it_be(:user) { create(:user) }

            let(:protected_branch_ids) { [protected_branch.id, group_protected_branch.id] }

            before do
              project.add_maintainer(user)
            end

            it 'associates the approval rule to the all protected branches' do
              expect(subject[:status]).to eq(:success)
              expect(subject[:rule].protected_branches).to match_array([protected_branch, group_protected_branch])
            end
          end
        end
      end

      context 'and multiple approval rules is disabled' do
        it 'does not associate the approval rule to the protected branch' do
          expect(subject[:status]).to eq(:success)
          expect(subject[:rule].protected_branches).to be_empty
        end
      end
    end

    context 'with rule_type set to :report_approver' do
      let(:result) { subject.execute }

      context 'without report_type' do
        subject { described_class.new(target, user, { name: 'License-Check', approvals_required: 1, rule_type: :report_approver }) }

        specify { expect(result[:status]).to eq(:error) }
      end

      context 'with report_type set to any of valid value' do
        using RSpec::Parameterized::TableSyntax

        subject { described_class.new(target, user, { name: rule_name, approvals_required: 1, rule_type: :report_approver, report_type: report_type }) }

        where(:rule_name, :report_type) do
          'License-Check'       | :license_scanning
          'Coverage-Check'      | :code_coverage
        end

        with_them do
          specify { expect(result[:status]).to eq(:success) }
          specify { expect(result[:rule].approvals_required).to eq(1) }
          specify { expect(result[:rule].rule_type).to eq('report_approver') }
        end
      end
    end
  end

  context 'when target is merge request' do
    let(:target) { create(:merge_request, source_project: project, target_project: project) }

    it_behaves_like "creatable"

    context 'when project rule id is present' do
      let_it_be(:project_user) { create(:user) }
      let_it_be(:public_group) { create(:group, :public) }

      let(:project_user_approvers) { [project_user] }
      let(:group_user_approvers) { [public_group] }
      let(:merge_request_approvers) { {} }
      let(:project_rule) do
        create(
          :approval_project_rule,
          project: project,
          name: 'bar',
          approvals_required: 1,
          users: project_user_approvers,
          groups: group_user_approvers
        )
      end

      let(:result) do
        described_class.new(target, user, {
          name: 'foo',
          approvals_required: 0,
          approval_project_rule_id: project_rule.id
        }.merge(merge_request_approvers)).execute
      end

      let(:rule) { result[:rule] }

      before do
        project.add_developer(project_user)
      end

      it 'associates with project rule and copies its properites' do
        expect(result[:status]).to eq(:success)
        expect(rule.approvals_required).to eq(0)
        expect(rule.approval_project_rule).to eq(project_rule)
        expect(rule.name).to eq(project_rule.name)
        expect(rule.rule_type).to eq('regular')
        expect(rule.users).to match(project_rule.users)
        expect(rule.groups).to match(project_rule.groups)
      end

      context 'when project rule includes no specific approvers' do
        let(:project_user_approvers) { User.none }
        let(:group_user_approvers) { Group.none }

        it 'associates with project rule and copies its properties' do
          expect(result[:status]).to eq(:success)
          expect(rule.approvals_required).to eq(0)
          expect(rule.approval_project_rule).to eq(project_rule)
          expect(rule.name).to eq(project_rule.name)
          expect(rule.rule_type).to eq('any_approver')
          expect(rule.users).to match([])
          expect(rule.groups).to match([])
        end
      end

      context 'when merge request includes empty approvers' do
        let(:merge_request_approvers) do
          {
            user_ids: [],
            group_ids: []
          }
        end

        it 'sets any approver' do
          expect(result[:status]).to eq(:success)
          expect(rule.name).to eq(project_rule.name)
          expect(rule.rule_type).to eq('any_approver')
          expect(rule.users).to eq([])
          expect(rule.groups).to eq([])
        end
      end

      context 'when merge request overrides approvers' do
        let(:merge_request_approvers) { { user_ids: [user.id] } }

        it 'sets single user as the approver' do
          expect(result[:status]).to eq(:success)
          expect(rule.name).to eq(project_rule.name)
          expect(rule.rule_type).to eq('regular')
          expect(rule.users).to eq([user])
          expect(rule.groups).to eq([])
        end
      end

      context 'when project rule is under the same project as MR' do
        let(:another_project) { create(:project) }

        before do
          project_rule.update!(project: another_project)
        end

        it 'ignores assignment' do
          expect(result[:status]).to eq(:success)
          expect(rule.approvals_required).to eq(0)
          expect(rule.approval_project_rule).to eq(nil)
        end

        it 'does not copy properties from project rule' do
          expect(rule.name).to eq('foo')
          expect(rule.users).to be_empty
          expect(rule.groups).to be_empty
        end
      end
    end
  end

  context 'audit event is streamed with correct event type', :request_store do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, creator: user, group: group) }
    let_it_be(:new_approvers) { create_list(:user, 2) }
    let_it_be(:new_groups) { create_list(:group, 2, :private) }
    let_it_be(:destination) { create(:external_audit_event_destination, group: group) }

    subject do
      described_class.new(
        project,
        user,
        { name: 'security',
          approvals_required: 1,
          user_ids: new_approvers.map(&:id),
          group_ids: new_groups.map(&:id) }
      ).execute
    end

    before do
      group.add_owner(user)
      stub_licensed_features(external_audit_events: true)
    end

    it_behaves_like 'sends correct event type in audit event stream' do
      let_it_be(:event_type) { 'approval_rule_created' }
    end
  end
end
