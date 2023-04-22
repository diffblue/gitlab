# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApprovalState do
  def create_rule(additional_params = {})
    params = additional_params.reverse_merge(merge_request: merge_request, users: [default_approver])
    factory =
      case params.delete(:rule_type)
      when :code_owner then :code_owner_rule
      when :report_approver then :report_approver_rule
      when :any_approver then :any_approver_rule
      else :approval_merge_request_rule
      end

    create(factory, params)
  end

  def approve_rules(rules)
    rules_to_approve = rules.select { |rule| rule.approvals_required > 0 }
    rules_to_approve.each do |rule|
      create(:approval, merge_request: merge_request, user: rule.users.first)
    end
  end

  def disable_feature
    allow(subject).to receive(:approval_feature_available?).and_return(false)
  end

  def users(amount)
    raise ArgumentError, 'not enough users' if amount > arbitrary_users.size

    arbitrary_users.take(amount)
  end

  let_it_be_with_refind(:project) { create(:project, :repository) }
  let_it_be_with_refind(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let_it_be(:approver1) { create(:user) }
  let_it_be(:approver2) { create(:user) }
  let_it_be(:approver3) { create(:user) }
  let_it_be(:default_approver) { create(:user) }
  let_it_be(:arbitrary_users) { create_list(:user, 2) }

  let_it_be(:group_approver1) { create(:user) }
  let_it_be(:group1) do
    group = create(:group)
    group.add_developer(group_approver1)
    group
  end

  subject { merge_request.approval_state }

  shared_examples 'filtering author and committers' do
    let(:committers) { [merge_request.author, create(:user, username: 'commiter')] }
    let(:merge_requests_disable_committers_approval) { nil }

    before do
      allow(merge_request).to receive(:committers).and_return(User.where(id: committers))

      allow(merge_request.project).to receive(:merge_requests_author_approval?).and_return(merge_requests_author_approval)
      allow(merge_request.project).to receive(:merge_requests_disable_committers_approval?).and_return(merge_requests_disable_committers_approval)

      create_rule(users: committers)
    end

    context 'when self approval is disabled on project' do
      let(:merge_requests_author_approval) { false }

      it 'excludes authors' do
        expect(results).not_to include(merge_request.author)
      end
    end

    context 'when self approval is enabled on project' do
      let(:merge_requests_author_approval) { true }

      it 'includes author' do
        expect(results).to include(merge_request.author)
      end
    end

    context 'when committers approval is enabled on project' do
      let(:merge_requests_author_approval) { true }
      let(:merge_requests_disable_committers_approval) { false }

      it 'includes committers' do
        expect(results).to include(*committers)
      end
    end

    context 'when committers approval is disabled on project' do
      let(:merge_requests_author_approval) { true }
      let(:merge_requests_disable_committers_approval) { true }

      it 'excludes committers' do
        expect(results).not_to include(*committers)
      end
    end
  end

  shared_examples_for 'a MR that all members with write access can approve' do
    it { expect(subject.eligible_for_approval_by?(developer)).to be_truthy }
    it { expect(subject.eligible_for_approval_by?(reporter)).to be_falsey }
    it { expect(subject.eligible_for_approval_by?(stranger)).to be_falsey }
    it { expect(subject.eligible_for_approval_by?(nil)).to be_falsey }
  end

  shared_context 'project members' do
    def create_project_member(role, user_attrs = {})
      user = create(:user, user_attrs)
      project.add_member(user, role)
      user
    end

    let_it_be_with_refind(:project) { create(:project, :repository) }
    let_it_be(:author) { create_project_member(:developer) }
    let_it_be_with_refind(:merge_request) { create(:merge_request, source_project: project, author: author) }
    let_it_be(:approver) { create_project_member(:developer) }
    let_it_be(:approver2) { create_project_member(:developer) }
    let_it_be(:developer) { create_project_member(:developer) }
    let_it_be(:other_developer) { create_project_member(:developer) }
    let_it_be(:reporter) { create_project_member(:reporter) }
    let_it_be(:stranger) { create(:user) }
  end

  describe '#approval_rules_overwritten?' do
    context 'when approval rule on the merge request does not exist' do
      it 'returns false' do
        expect(subject.approval_rules_overwritten?).to eq(false)
      end
    end

    context 'when merge request has any approver rule' do
      let!(:any_approver_rule) { create(:any_approver_rule, merge_request: merge_request) }

      it 'returns true' do
        expect(subject.approval_rules_overwritten?).to eq(true)
      end

      context 'when overriding approvals is not allowed' do
        before do
          project.update!(disable_overriding_approvers_per_merge_request: true)
        end

        it 'returns true' do
          expect(subject.approval_rules_overwritten?).to eq(false)
        end
      end
    end
  end

  context 'when multiple rules are allowed' do
    before do
      stub_licensed_features(multiple_approval_rules: true)
    end

    describe '#wrapped_approval_rules' do
      before do
        2.times { create_rule }
      end

      it 'returns all rules in wrapper' do
        expect(subject.wrapped_approval_rules).to all(be_an(ApprovalWrappedRule))
        expect(subject.wrapped_approval_rules.size).to eq(2)
      end

      context 'when approval feature is unavailable' do
        it 'returns empty array' do
          disable_feature

          expect(subject.wrapped_approval_rules).to eq([])
        end
      end
    end

    context 'with multiple scan_finding rules' do
      before do
        2.times { create_rule({ rule_type: :report_approver, report_type: :scan_finding }) }
        2.times { create_rule({ rule_type: :report_approver, report_type: :scan_finding, orchestration_policy_idx: 1 }) }
      end

      it 'returns one rule for each orchestration_policy_idx' do
        approval_rules = subject.wrapped_approval_rules

        expect(approval_rules.count).to be(2)
        expect(approval_rules).to all(be_instance_of(ApprovalWrappedRule))

        policy_indices = approval_rules.map { |rule| rule.approval_rule.orchestration_policy_idx }

        expect(policy_indices).to contain_exactly(nil, 1)
      end
    end

    describe '#approval_needed?' do
      context 'when feature not available' do
        it 'returns false' do
          allow(subject.project).to receive(:feature_available?).with(:merge_request_approvers).and_return(false)

          expect(subject.approval_needed?).to eq(false)
        end
      end

      context 'when overall approvals required is not zero' do
        let!(:any_approver_rule) do
          create(:approval_project_rule, project: project, rule_type: :any_approver, approvals_required: 1)
        end

        it 'returns true' do
          expect(subject.approval_needed?).to eq(true)
        end
      end

      context "when any rule's approvals required is not zero" do
        it 'returns false' do
          create_rule(approvals_required: 1)

          expect(subject.approval_needed?).to eq(true)
        end
      end

      context "when overall approvals required and all rule's approvals_required are zero" do
        it 'returns false' do
          create_rule(approvals_required: 0)

          expect(subject.approval_needed?).to eq(false)
        end
      end

      context "when overall approvals required is zero, and there is no rule" do
        it 'returns false' do
          expect(subject.approval_needed?).to eq(false)
        end
      end

      context 'when approval feature is unavailable' do
        it 'returns false' do
          disable_feature

          expect(subject.approval_needed?).to eq(false)
        end
      end
    end

    describe '#approved?' do
      shared_examples_for 'when rules are present' do
        context 'when all rules are approved' do
          before do
            approve_rules(subject.wrapped_approval_rules)
          end

          it 'returns true' do
            expect(subject.approved?).to eq(true)
          end
        end

        context 'when some rules are not approved' do
          before do
            allow(subject.wrapped_approval_rules.first).to receive(:approved?).and_return(false)
          end

          it 'returns false' do
            expect(subject.approved?).to eq(false)
          end
        end
      end

      shared_examples_for 'checking any_approver rule' do
        let!(:any_approver_rule) do
          create(:approval_project_rule, project: project, rule_type: :any_approver, approvals_required: 1)
        end

        context 'when it is not met' do
          it 'returns false' do
            expect(subject.approved?).to eq(false)
          end
        end

        context 'when it is met' do
          it 'returns true' do
            create(:approval, merge_request: merge_request)

            expect(subject.approved?).to eq(true)
          end
        end
      end

      context 'when no rules' do
        it_behaves_like 'checking any_approver rule'
      end

      context 'when only code owner rules present' do
        before do
          users(2).each { |user| create_rule(users: [user], rule_type: :code_owner) }
        end

        it_behaves_like 'when rules are present'
        it_behaves_like 'checking any_approver rule'
      end

      context 'when only report approver rules present' do
        before do
          users(2).each { |user| create_rule(users: [user], rule_type: :report_approver) }
        end

        it_behaves_like 'when rules are present'
        it_behaves_like 'checking any_approver rule'
      end

      context 'when regular rules present' do
        before do
          users(2).each { |user| create_rule(users: [user]) }
        end

        it_behaves_like 'when rules are present'
      end

      context 'when approval feature is unavailable' do
        it 'returns true' do
          disable_feature
          create_rule(users: users(1), approvals_required: 1)

          expect(subject.approved?).to eq(true)
        end
      end
    end

    describe '#approvals_left' do
      before do
        create_rule(approvals_required: 5)
        create_rule(approvals_required: 7)
      end

      it 'sums approvals_left from rules' do
        expect(subject.approvals_left).to eq(12)
      end

      context 'with any approval rule' do
        it 'sums approvals_left from regular rules' do
          create_rule(rule_type: :any_approver, approvals_required: 20)

          expect(subject.approvals_left).to eq(20)
        end
      end

      context 'with report approver rule' do
        it 'sums code_owner_rules_left from report approver rules' do
          create_rule(rule_type: :report_approver, approvals_required: 20)

          expect(subject.approvals_left).to eq(32)
        end
      end

      context 'when approval feature is unavailable' do
        it 'returns 0' do
          disable_feature

          expect(subject.approvals_left).to eq(0)
        end
      end
    end

    describe '#approval_rules_left' do
      def create_unapproved_rule
        create_rule(approvals_required: 1, users: users(1))
      end

      before do
        2.times { create_unapproved_rule }
      end

      it 'counts approval_rules left' do
        expect(subject.approval_rules_left.size).to eq(2)
      end

      context 'when approval feature is unavailable' do
        it 'returns empty array' do
          disable_feature

          expect(subject.approval_rules_left).to eq([])
        end
      end
    end

    describe '#approvals_required' do
      it "correctly sums the approvals" do
        create_rule(approvals_required: 3)
        create_rule(approvals_required: 10)

        expect(subject.approvals_required).to eq(13)
      end
    end

    describe '#approvers' do
      it 'includes all approvers, including code owner and group members' do
        create_rule(users: [approver1])
        create_rule(users: [approver1], groups: [group1])

        expect(subject.approvers).to contain_exactly(approver1, group_approver1)
      end

      it_behaves_like 'filtering author and committers' do
        let(:results) { subject.approvers }
      end
    end

    describe '#filtered_approvers' do
      describe 'only direct users, without code owners' do
        it 'includes only rule user members' do
          create_rule(users: [approver1])
          create_rule(users: [approver1], groups: [group1])
          create_rule(users: [approver2], rule_type: :code_owner)
          create_rule(users: [approver3], rule_type: :report_approver)

          expect(
            subject.filtered_approvers(code_owner: false, target: :users)
          ).to contain_exactly(approver1, approver3)
        end
      end

      describe 'only unactioned' do
        it 'excludes approved approvers' do
          create_rule(users: [approver1])
          create_rule(users: [approver1], groups: [group1])
          create_rule(users: [approver2], rule_type: :code_owner)
          create_rule(users: [approver3], rule_type: :report_approver)

          create(:approval, merge_request: merge_request, user: approver1)

          expect(subject.filtered_approvers(unactioned: true)).to contain_exactly(approver2, approver3, group_approver1)
        end
      end

      it_behaves_like 'filtering author and committers' do
        let(:results) { subject.filtered_approvers }
      end
    end

    describe '#unactioned_approvers' do
      it 'sums approvals_left from rules' do
        create_rule(users: [approver1, approver2])
        create_rule(users: [approver1])

        merge_request.approvals.create!(user: approver2)

        expect(subject.unactioned_approvers).to contain_exactly(approver1)
      end

      it_behaves_like 'filtering author and committers' do
        let(:results) { subject.unactioned_approvers }
      end
    end

    describe '#eligible_for_approval_by?' do
      shared_examples_for 'authors self-approval authorization' do
        context 'when authors are authorized to approve their own MRs' do
          before do
            merge_request.project.update!(merge_requests_author_approval: true)
            merge_request.project.clear_memoization(:merge_requests_author_approval)
          end

          it 'allows the author to approve the MR if within the approvers list' do
            expect(subject.eligible_for_approval_by?(author)).to be_truthy
          end
        end

        context 'when authors are not authorized to approve their own MRs' do
          it 'does not allow the author to approve the MR' do
            expect(subject.eligible_for_approval_by?(author)).to be_falsey
          end
        end
      end

      include_context 'project members' do
        let_it_be(:committer) { create_project_member(:developer, email: merge_request.commits.without_merge_commits.first.committer_email) }
      end

      context 'when there are no regular approval rules' do
        let!(:any_approver_rule) do
          create(:approval_project_rule, project: project, rule_type: :any_approver, approvals_required: 1)
        end

        it_behaves_like 'a MR that all members with write access can approve'

        it 'requires one approval' do
          expect(subject.approvals_left).to eq(1)
        end

        context 'when authors are authorized to approve their own MRs' do
          before do
            project.update!(merge_requests_author_approval: true)
          end

          it 'allows the author to approve the MR if within the approvers list' do
            expect(subject.eligible_for_approval_by?(author)).to be_truthy
          end

          it 'allows the author to approve the MR if not within the approvers list' do
            allow(subject).to receive(:approvers).and_return([])

            expect(subject.eligible_for_approval_by?(author)).to be_truthy
          end

          context 'when the author has approved the MR already' do
            before do
              create(:approval, user: author, merge_request: merge_request)
            end

            it 'does not allow the author to approve the MR again' do
              expect(subject.eligible_for_approval_by?(author)).to be_falsey
            end
          end
        end

        context 'when authors are not authorized to approve their own MRs' do
          before do
            project.update!(merge_requests_author_approval: false)
          end

          it 'allows the author to approve the MR if within the approvers list' do
            allow(subject).to receive(:approvers).and_return([author])

            expect(subject.eligible_for_approval_by?(author)).to be_truthy
          end

          it 'does not allow the author to approve the MR if not within the approvers list' do
            allow(subject).to receive(:approvers).and_return([])

            expect(subject.eligible_for_approval_by?(author)).to be_falsey
          end
        end

        context 'when committers are authorized to approve their own MRs' do
          before do
            project.update!(merge_requests_disable_committers_approval: false)
          end

          it 'allows the committer to approve the MR if within the approvers list' do
            allow(subject).to receive(:approvers).and_return([committer])

            expect(subject.eligible_for_approval_by?(committer)).to be_truthy
          end

          it 'allows the committer to approve the MR if not within the approvers list' do
            allow(subject).to receive(:approvers).and_return([])

            expect(subject.eligible_for_approval_by?(committer)).to be_truthy
          end

          context 'when the committer has approved the MR already' do
            before do
              create(:approval, user: committer, merge_request: merge_request)
            end

            it 'does not allow the committer to approve the MR again' do
              expect(subject.eligible_for_approval_by?(committer)).to be_falsey
            end
          end
        end

        context 'when committers are not authorized to approve their own MRs' do
          before do
            project.update!(merge_requests_disable_committers_approval: true)
          end

          it 'allows the committer to approve the MR if within the approvers list' do
            allow(subject).to receive(:approvers).and_return([committer])

            expect(subject.eligible_for_approval_by?(committer)).to be_truthy
          end

          it 'does not allow the committer to approve the MR if not within the approvers list' do
            allow(subject).to receive(:approvers).and_return([])

            expect(subject.eligible_for_approval_by?(committer)).to be_falsey
          end
        end

        context 'when the user is both an author and a committer' do
          let(:user) { committer }

          before do
            merge_request.update!(author: committer)
          end

          context 'when authors are authorized to approve their own MRs, but not committers' do
            before do
              project.update!(
                merge_requests_author_approval: true,
                merge_requests_disable_committers_approval: true
              )
            end

            it 'allows the user to approve the MR if within the approvers list' do
              allow(subject).to receive(:approvers).and_return([user])

              expect(subject.eligible_for_approval_by?(user)).to be_truthy
            end

            it 'does not allow the user to approve the MR if not within the approvers list' do
              allow(subject).to receive(:approvers).and_return([])

              expect(subject.eligible_for_approval_by?(user)).to be_falsey
            end
          end

          context 'when committers are authorized to approve their own MRs, but not authors' do
            before do
              project.update!(
                merge_requests_author_approval: false,
                merge_requests_disable_committers_approval: false
              )
            end

            it 'allows the user to approve the MR if within the approvers list' do
              allow(subject).to receive(:approvers).and_return([user])

              expect(subject.eligible_for_approval_by?(user)).to be_truthy
            end

            it 'does not allow the user to approve the MR if not within the approvers list' do
              allow(subject).to receive(:approvers).and_return([])

              expect(subject.eligible_for_approval_by?(user)).to be_falsey
            end
          end
        end
      end

      context 'when there is one approver required' do
        let!(:any_approver_rule) { create_rule(rule_type: :any_approver, approvals_required: 1) }
        let!(:rule) { create_rule(approvals_required: 1, users: [author]) }

        context 'when that approver is the MR author' do
          it_behaves_like 'authors self-approval authorization'

          it_behaves_like 'a MR that all members with write access can approve'

          it 'does not allow a logged-out user to approve the MR' do
            expect(subject.eligible_for_approval_by?(nil)).to be_falsey
          end

          it 'is not approved' do
            expect(subject.approvals_left).to eq(1)
            expect(subject.approved?).to eq(false)
          end
        end
      end

      context 'when there are multiple approvers required' do
        let!(:rule) { create_rule(approvals_required: 3) }

        context 'when one of those approvers is the MR author' do
          before do
            rule.users = [author, approver, approver2]
          end

          it_behaves_like 'authors self-approval authorization'

          it 'requires the original number of approvals' do
            expect(subject.approvals_left).to eq(3)
          end

          it 'allows any other other approver to approve the MR' do
            expect(subject.eligible_for_approval_by?(approver)).to be_truthy
          end

          it 'does not allow a logged-out user to approve the MR' do
            expect(subject.eligible_for_approval_by?(nil)).to be_falsey
          end

          context 'when self-approval is disabled and all of the valid approvers have approved the MR' do
            before do
              create(:approval, user: approver, merge_request: merge_request)
              create(:approval, user: approver2, merge_request: merge_request)
            end

            it_behaves_like 'a MR that all members with write access can approve'

            it 'requires the original number of approvals' do
              expect(subject.approvals_left).to eq(1)
            end

            it 'does not allow the author to approve the MR' do
              expect(subject.eligible_for_approval_by?(author)).to be_falsey
            end

            it 'does not allow the approvers to approve the MR again' do
              expect(subject.eligible_for_approval_by?(approver)).to be_falsey
              expect(subject.eligible_for_approval_by?(approver2)).to be_falsey
            end
          end

          context 'when self-approval is enabled and all of the valid approvers have approved the MR' do
            before do
              merge_request.project.update!(merge_requests_author_approval: true)
              create(:approval, user: author, merge_request: merge_request)
              create(:approval, user: approver2, merge_request: merge_request)
              merge_request.project.clear_memoization(:merge_requests_author_approval)
            end

            it 'requires the original number of approvals' do
              expect(subject.approvals_left).to eq(1)
            end

            it 'does not allow the approvers to approve the MR again' do
              expect(subject.eligible_for_approval_by?(author)).to be_falsey
              expect(subject.eligible_for_approval_by?(approver2)).to be_falsey
            end

            it 'allows any other project member with write access to approve the MR' do
              expect(subject.eligible_for_approval_by?(reporter)).to be_falsey
              expect(subject.eligible_for_approval_by?(stranger)).to be_falsey
              expect(subject.eligible_for_approval_by?(nil)).to be_falsey
            end
          end

          context 'when all approvers have approved the MR' do
            before do
              create(:approval, user: approver, merge_request: merge_request)
              create(:approval, user: approver2, merge_request: merge_request)
              create(:approval, user: developer, merge_request: merge_request)
            end

            it 'is approved' do
              expect(subject).to be_approved
            end

            it "returns sum of each rule's approvals_left" do
              expect(subject.approvals_left).to eq(1)
            end
          end
        end

        context 'when the approvers do not contain the MR author' do
          before do
            rule.users = [developer, approver, approver2]
          end

          it 'requires the original number of approvals' do
            expect(subject.approvals_left).to eq(3)
          end

          it 'allows anyone with write access except for author to approve the MR' do
            expect(subject.eligible_for_approval_by?(developer)).to be_truthy
            expect(subject.eligible_for_approval_by?(approver)).to be_truthy
            expect(subject.eligible_for_approval_by?(approver2)).to be_truthy

            expect(subject.eligible_for_approval_by?(author)).to be_falsey
            expect(subject.eligible_for_approval_by?(reporter)).to be_falsey
            expect(subject.eligible_for_approval_by?(stranger)).to be_falsey
            expect(subject.eligible_for_approval_by?(nil)).to be_falsey
          end
        end
      end

      describe '#any_approver_rules' do
        let(:approval_rule) { subject.wrapped_approval_rules.last.approval_rule }

        context 'a project with any_approver rule' do
          let!(:project_rule) do
            create(:approval_project_rule, rule_type: :any_approver, project: project)
          end

          it 'returns project rules' do
            expect(subject.wrapped_approval_rules.size).to eq(1)
            expect(approval_rule).to eq(project_rule)
          end

          context 'a merge request with regular rule' do
            let!(:rule) { create_rule(rule_type: :any_approver, approvals_required: 2) }

            it 'returns merge request rules' do
              expect(subject.wrapped_approval_rules.size).to eq(1)
              expect(approval_rule).to eq(rule)
            end
          end
        end
      end

      context 'when any_approver rule with 2 approvals required exist' do
        let!(:rule) { create_rule(rule_type: :any_approver, approvals_required: 2) }

        it_behaves_like 'a MR that all members with write access can approve'

        it 'requires the 2 approvals' do
          expect(subject.approvals_left).to eq(2)
        end

        context 'a user approves the MR' do
          before do
            create(:approval, merge_request: merge_request, user: approver)
          end

          it 'requires 1 approval' do
            expect(merge_request.approved_by?(approver)).to eq(true)
            expect(subject.approvals_left).to eq(1)
          end

          context 'another user approves the MR' do
            before do
              create(:approval, merge_request: merge_request, user: approver1)
            end

            it 'becomes approved' do
              expect(merge_request.approved_by?(approver1)).to eq(true)
              expect(subject.approved?).to eq(true)
            end
          end
        end
      end
    end

    describe '#authors_can_approve?' do
      context 'allow_author_approval is resolved to not be permitted' do
        before do
          allow_next_instance_of ComplianceManagement::MergeRequestApprovalSettings::Resolver do |instance|
            allow(instance).to receive(:allow_author_approval).and_return(
              ComplianceManagement::MergeRequestApprovalSettings::Setting.new(value: false, locked: false, inherited_from: nil)
            )
          end
        end

        it 'returns false' do
          expect(subject.authors_can_approve?).to be false
        end
      end

      context 'allow_author_approval is resolved to be permitted' do
        before do
          allow_next_instance_of ComplianceManagement::MergeRequestApprovalSettings::Resolver do |instance|
            allow(instance).to receive(:allow_author_approval).and_return(
              ComplianceManagement::MergeRequestApprovalSettings::Setting.new(value: true, locked: false, inherited_from: nil)
            )
          end
        end

        it 'returns true' do
          expect(subject.authors_can_approve?).to be true
        end
      end
    end

    describe '#committers_can_approve?' do
      context 'allow_committer_approval is resolved to not be permitted' do
        before do
          allow_next_instance_of ComplianceManagement::MergeRequestApprovalSettings::Resolver do |instance|
            allow(instance).to receive(:allow_committer_approval).and_return(
              ComplianceManagement::MergeRequestApprovalSettings::Setting.new(value: false, locked: false, inherited_from: nil)
            )
          end
        end

        it 'returns false' do
          expect(subject.committers_can_approve?).to be false
        end
      end

      context 'allow_committer_approval is resolved to be permitted' do
        before do
          allow_next_instance_of ComplianceManagement::MergeRequestApprovalSettings::Resolver do |instance|
            allow(instance).to receive(:allow_committer_approval).and_return(
              ComplianceManagement::MergeRequestApprovalSettings::Setting.new(value: true, locked: false, inherited_from: nil)
            )
          end
        end

        it 'returns false' do
          expect(subject.committers_can_approve?).to be true
        end
      end
    end

    describe '#suggested_approvers' do
      let(:user) { create(:user) }
      let(:public_group) { create(:group, :public) }
      let(:private_group) { create(:group, :private) }

      let!(:private_user) { create(:group_member, group: private_group).user }
      let!(:public_user) { create(:group_member, group: public_group).user }
      let!(:rule1) { create_rule(groups: [private_group], users: []) }
      let!(:rule2) { create_rule(groups: [public_group], users: []) }

      subject { merge_request.approval_state.suggested_approvers(current_user: user) }

      context 'user cannot see private group' do
        it 'shows public users' do
          is_expected.to contain_exactly(public_user)
        end

        it 'does not show users who have already approved' do
          create(:approval, merge_request: merge_request, user: public_user)

          is_expected.to be_empty
        end
      end

      context 'user can see private group' do
        before do
          create(:group_member, group: private_group, user: user)
        end

        it 'shows private users' do
          is_expected.to contain_exactly(public_user, private_user, user)
        end
      end
    end
  end

  context 'when only a single rule is allowed' do
    def create_unapproved_rule(additional_params = {})
      create_rule(
        additional_params.reverse_merge(approvals_required: 1, users: users(1))
      )
    end

    def create_rules
      rule1
      rule2
      code_owner_rule
      report_approver_rule
    end

    let(:rule1) { create_unapproved_rule }
    let(:rule2) { create_unapproved_rule }
    let(:code_owner_rule) { create_unapproved_rule(rule_type: :code_owner, approvals_required: 0) }
    let(:report_approver_rule) { create_unapproved_rule(rule_type: :report_approver, approvals_required: 0) }

    before do
      stub_licensed_features multiple_approval_rules: false
    end

    describe '#wrapped_approval_rules' do
      it 'returns one regular rule in wrapper' do
        create_rules

        subject.wrapped_approval_rules.each do |rule|
          expect(rule.is_a?(ApprovalWrappedRule)).to eq(true)
        end

        expect(subject.wrapped_approval_rules.size).to eq(3)
      end
    end

    describe '#approval_needed?' do
      context 'when feature not available' do
        it 'returns false' do
          allow(subject.project).to receive(:feature_available?).with(:merge_request_approvers).and_return(false)

          expect(subject.approval_needed?).to eq(false)
        end
      end

      context 'when overall approvals required is not zero' do
        before do
          project.update!(approvals_before_merge: 1)
        end

        it 'returns true' do
          expect(subject.approval_needed?).to eq(true)
        end
      end

      context "when any rule's approvals required is not zero" do
        it 'returns false' do
          create_rule(approvals_required: 1)

          expect(subject.approval_needed?).to eq(true)
        end
      end

      context "when overall approvals required and all rule's approvals_required are zero" do
        it 'returns false' do
          create_rule(approvals_required: 0)

          expect(subject.approval_needed?).to eq(false)
        end
      end

      context "when overall approvals required is zero, and there is no rule" do
        it 'returns false' do
          expect(subject.approval_needed?).to eq(false)
        end
      end
    end

    describe '#approved?' do
      shared_examples_for 'when rules are present' do
        context 'when all rules are approved' do
          before do
            approve_rules(subject.wrapped_approval_rules)
          end

          it 'returns true' do
            expect(subject.approved?).to eq(true)
          end
        end

        context 'when some rules are not approved' do
          before do
            allow(subject.wrapped_approval_rules.first).to receive(:approved?).and_return(false)
          end

          it 'returns false' do
            expect(subject.approved?).to eq(false)
          end
        end
      end

      shared_examples_for 'checking any_approver rule' do
        before do
          project.update!(approvals_before_merge: 1)
        end

        context 'when it is not met' do
          it 'returns false' do
            expect(subject.approved?).to eq(false)
          end
        end

        context 'when it is met' do
          it 'returns true' do
            create(:approval, merge_request: merge_request)

            expect(subject.approved?).to eq(true)
          end
        end
      end

      context 'when no rules' do
        it_behaves_like 'checking any_approver rule'
      end

      context 'when only code owner rules present' do
        before do
          # setting approvals required to 0 since we don't want to block on them now
          users(2).each { |user| create_rule(users: [user], rule_type: :code_owner, approvals_required: 0) }
        end

        it_behaves_like 'when rules are present'
        it_behaves_like 'checking any_approver rule'
      end

      context 'when only report approver rules present' do
        before do
          users(2).each { |user| create_rule(users: [user], rule_type: :report_approver) }
        end

        it_behaves_like 'when rules are present'
        it_behaves_like 'checking any_approver rule'
      end

      context 'when regular rules present' do
        before do
          project.update!(approvals_before_merge: 999)
          users(2).each { |user| create_rule(users: [user]) }
        end

        it_behaves_like 'when rules are present'
      end

      context 'when a single project rule is present' do
        before do
          create(:approval_project_rule, users: users(1), project: project)
        end

        it_behaves_like 'when rules are present'

        context 'when the project rule is overridden by a fallback but the project does not allow overriding' do
          before do
            merge_request.update!(approvals_before_merge: 1)
            merge_request.project.update!(disable_overriding_approvers_per_merge_request: true)
          end

          it_behaves_like 'when rules are present'
        end

        context 'when the project rule is overridden by a fallback' do
          before do
            merge_request.update!(approvals_before_merge: 1)
          end

          it_behaves_like 'checking any_approver rule'
        end
      end

      context 'when a single project rule is present that is overridden in the merge request' do
        before do
          create(:approval_project_rule, users: users(1), project: project)
          merge_request.update!(approvals_before_merge: 1)
        end

        it_behaves_like 'checking any_approver rule'
      end
    end

    describe '#approvals_left' do
      let(:rule1) { create_unapproved_rule(approvals_required: 5) }
      let(:rule2) { create_unapproved_rule(approvals_required: 7) }

      it 'sums approvals_left from rules' do
        create_rules

        expect(subject.approvals_left).to eq(5)
      end
    end

    describe '#approval_rules_left' do
      it 'counts approval_rules left' do
        create_rules

        expect(subject.approval_rules_left.size).to eq(1)
      end
    end

    describe '#approvers' do
      let(:code_owner_rule) { create_rule(rule_type: :code_owner, groups: [group1]) }
      let(:report_approver_rule) { create_rule(rule_type: :report_approver, users: [approver2]) }

      it 'includes approvers from first rule, code owner rule, and report approver rule' do
        create_rules
        approvers = rule1.users + code_owner_rule.users + [group_approver1, approver2]

        expect(subject.approvers).to contain_exactly(*approvers)
      end

      it_behaves_like 'filtering author and committers' do
        let(:results) { subject.approvers }
      end
    end

    describe '#filtered_approvers' do
      describe 'only direct users, without code owners' do
        it 'excludes code owners' do
          create_rule(users: [approver1])
          create_rule(users: [approver1], groups: [group1])
          create_rule(users: [approver2], rule_type: :code_owner)
          create_rule(users: [approver3], rule_type: :report_approver)

          expect(
            subject.filtered_approvers(code_owner: false, target: :users)
          ).to contain_exactly(approver1, approver3)
        end
      end

      describe 'only unactioned' do
        it 'excludes approved approvers' do
          create_rule(users: [approver1])
          create_rule(users: [approver1], groups: [group1])
          create_rule(users: [approver2], rule_type: :code_owner)
          create_rule(users: [approver3], rule_type: :report_approver)

          create(:approval, merge_request: merge_request, user: approver1)

          expect(subject.filtered_approvers(unactioned: true)).to contain_exactly(approver2, approver3)
        end
      end

      it_behaves_like 'filtering author and committers' do
        let(:results) { subject.filtered_approvers }
      end
    end

    describe '#unactioned_approvers' do
      it 'sums approvals_left from rules' do
        create_rule(users: [approver1, approver2])
        create_rule(users: [approver1])

        merge_request.approvals.create!(user: approver2)

        expect(subject.unactioned_approvers).to contain_exactly(approver1)
      end

      it_behaves_like 'filtering author and committers' do
        let(:results) { subject.unactioned_approvers }
      end
    end

    describe '#eligible_for_approval_by?' do
      shared_examples_for 'authors self-approval authorization' do
        context 'when authors are authorized to approve their own MRs' do
          before do
            merge_request.project.update!(merge_requests_author_approval: true)
            merge_request.project.clear_memoization(:merge_requests_author_approval)
          end

          it 'allows the author to approve the MR if within the approvers list' do
            expect(subject.eligible_for_approval_by?(author)).to be_truthy
          end
        end

        context 'when authors are not authorized to approve their own MRs' do
          it 'does not allow the author to approve the MR' do
            expect(subject.eligible_for_approval_by?(author)).to be_falsey
          end
        end
      end

      include_context 'project members' do
        let_it_be(:guest) { create_project_member(:guest) }
      end

      context 'when the user is the author' do
        context 'and author is an approver' do
          before do
            create(:approval_project_rule, project: project, users: [author])
          end

          it 'returns true when authors can approve' do
            project.update!(merge_requests_author_approval: true)

            expect(subject.eligible_for_approval_by?(author)).to be true
          end

          it 'returns false when authors cannot approve' do
            project.update!(merge_requests_author_approval: false)

            expect(subject.eligible_for_approval_by?(author)).to be false
          end
        end

        context 'and author is not an approver' do
          it 'returns true when authors can approve' do
            project.update!(merge_requests_author_approval: true)

            expect(subject.eligible_for_approval_by?(author)).to be true
          end

          it 'returns false when authors cannot approve' do
            project.update!(merge_requests_author_approval: false)

            expect(subject.eligible_for_approval_by?(author)).to be false
          end
        end
      end

      context 'when user is a committer' do
        let_it_be(:user) { create(:user, email: merge_request.commits.without_merge_commits.first.committer_email) }

        before_all do
          project.add_developer(user)
        end

        context 'and committer is an approver' do
          before do
            create(:approval_project_rule, project: project, users: [user])
          end

          it 'return true when committers can approve' do
            project.update!(merge_requests_disable_committers_approval: false)

            expect(subject.eligible_for_approval_by?(user)).to be true
          end

          it 'return false when committers cannot approve' do
            project.update!(merge_requests_disable_committers_approval: true)

            expect(subject.eligible_for_approval_by?(user)).to be false
          end
        end

        context 'and committer is not an approver' do
          it 'return true when committers can approve' do
            project.update!(merge_requests_disable_committers_approval: false)

            expect(subject.eligible_for_approval_by?(user)).to be true
          end

          it 'return false when committers cannot approve' do
            project.update!(merge_requests_disable_committers_approval: true)

            expect(subject.eligible_for_approval_by?(user)).to be false
          end
        end
      end

      context 'when there is one approver required' do
        let!(:rule) { create_rule(approvals_required: 1, users: [author]) }
        let!(:any_approver_rule) { create_rule(rule_type: :any_approver, approvals_required: 1) }

        context 'when that approver is the MR author' do
          it_behaves_like 'authors self-approval authorization'

          it_behaves_like 'a MR that all members with write access can approve'

          it 'requires one approval' do
            expect(subject.approvals_left).to eq(1)
          end

          it 'does not allow a logged-out user to approve the MR' do
            expect(subject.eligible_for_approval_by?(nil)).to be_falsey
          end

          it 'is not approved' do
            expect(subject.approved?).to eq(false)
          end
        end
      end

      context 'when there are multiple approvers required' do
        let!(:rule) { create_rule(approvals_required: 3) }

        context 'when one of those approvers is the MR author' do
          before do
            rule.users = [author, approver, approver2]
          end

          it_behaves_like 'authors self-approval authorization'

          it 'requires the original number of approvals' do
            expect(subject.approvals_left).to eq(3)
          end

          it 'allows any other other approver to approve the MR' do
            expect(subject.eligible_for_approval_by?(approver)).to be_truthy
          end

          it 'does not allow a logged-out user to approve the MR' do
            expect(subject.eligible_for_approval_by?(nil)).to be_falsey
          end

          context 'when self-approval is disabled and all of the valid approvers have approved the MR' do
            before do
              create(:approval, user: approver, merge_request: merge_request)
              create(:approval, user: approver2, merge_request: merge_request)
            end

            it_behaves_like 'a MR that all members with write access can approve'

            it 'requires the original number of approvals' do
              expect(subject.approvals_left).to eq(1)
            end

            it 'does not allow the author to approve the MR' do
              expect(subject.eligible_for_approval_by?(author)).to be_falsey
            end

            it 'does not allow the approvers to approve the MR again' do
              expect(subject.eligible_for_approval_by?(approver)).to be_falsey
              expect(subject.eligible_for_approval_by?(approver2)).to be_falsey
            end
          end

          context 'when self-approval is enabled and all of the valid approvers have approved the MR' do
            before do
              merge_request.project.update!(merge_requests_author_approval: true)
              create(:approval, user: author, merge_request: merge_request)
              create(:approval, user: approver2, merge_request: merge_request)
              merge_request.project.clear_memoization(:merge_requests_author_approval)
            end

            it 'requires the original number of approvals' do
              expect(subject.approvals_left).to eq(1)
            end

            it 'does not allow the approvers to approve the MR again' do
              expect(subject.eligible_for_approval_by?(author)).to be_falsey
              expect(subject.eligible_for_approval_by?(approver2)).to be_falsey
            end

            it 'allows any other project member with write access to approve the MR' do
              expect(subject.eligible_for_approval_by?(reporter)).to be_falsey
              expect(subject.eligible_for_approval_by?(stranger)).to be_falsey
              expect(subject.eligible_for_approval_by?(nil)).to be_falsey
            end
          end

          context 'when all approvers have approved the MR' do
            before do
              create(:approval, user: approver, merge_request: merge_request)
              create(:approval, user: approver2, merge_request: merge_request)
              create(:approval, user: developer, merge_request: merge_request)
            end

            it 'is approved' do
              expect(subject).to be_approved
            end

            it "returns sum of each rule's approvals_left" do
              expect(subject.approvals_left).to eq(1)
            end
          end
        end

        context 'when the approvers do not contain the MR author' do
          before do
            rule.users = [developer, approver, approver2]
          end

          it 'requires the original number of approvals' do
            expect(subject.approvals_left).to eq(3)
          end

          it 'allows anyone with write access except for author to approve the MR' do
            expect(subject.eligible_for_approval_by?(developer)).to be_truthy
            expect(subject.eligible_for_approval_by?(approver)).to be_truthy
            expect(subject.eligible_for_approval_by?(approver2)).to be_truthy

            expect(subject.eligible_for_approval_by?(author)).to be_falsey
            expect(subject.eligible_for_approval_by?(reporter)).to be_falsey
            expect(subject.eligible_for_approval_by?(guest)).to be_falsey
            expect(subject.eligible_for_approval_by?(stranger)).to be_falsey
            expect(subject.eligible_for_approval_by?(nil)).to be_falsey
          end

          context 'when an approver does not have access to the merge request', :sidekiq_inline do
            before do
              project.members.find_by(user_id: developer.id).destroy!
            end

            it 'the user cannot approver' do
              expect(subject.eligible_for_approval_by?(developer)).to be_falsey
            end
          end
        end
      end
    end

    describe '#authors_can_approve?' do
      context 'when project allows author approval' do
        before do
          project.update!(merge_requests_author_approval: true)
        end

        it 'returns true' do
          expect(subject.authors_can_approve?).to eq(true)
        end
      end

      context 'when project disallows author approval' do
        before do
          project.update!(merge_requests_author_approval: false)
        end

        it 'returns true' do
          expect(subject.authors_can_approve?).to eq(false)
        end
      end
    end
  end

  describe '#user_defined_rules' do
    context 'when approval rules are not overwritten' do
      let!(:project_rule) { create(:approval_project_rule, project: project) }
      let!(:another_project_rule) { create(:approval_project_rule, project: project) }

      context 'and multiple approval rules is disabled' do
        it 'returns the first rule' do
          expect(subject.user_defined_rules.map(&:approval_rule)).to match_array(
            [
              project_rule
            ])
        end
      end

      context 'and multiple approval rules is enabled' do
        before do
          stub_licensed_features(multiple_approval_rules: true)
        end

        it 'returns the rules as is' do
          expect(subject.user_defined_rules.map(&:approval_rule)).to match_array(
            [
              project_rule,
              another_project_rule
            ])
        end

        context 'and rules are scoped by protected branches' do
          let(:protected_branch) { create(:protected_branch, project: project, name: 'stable-*') }
          let(:another_protected_branch) { create(:protected_branch, project: project, name: '*-stable') }

          before do
            merge_request.update!(target_branch: 'stable-1')
            another_project_rule.update!(protected_branches: [protected_branch])
            project_rule.update!(protected_branches: [another_protected_branch])
          end

          it 'returns the rules that are applicable to the merge request target branch' do
            expect(subject.user_defined_rules.map(&:approval_rule)).to eq(
              [
                another_project_rule
              ])
          end

          context 'and target_branch is specified' do
            subject { described_class.new(merge_request, target_branch: 'v1-stable') }

            it 'returns the rules that are applicable to the specified target_branch' do
              expect(subject.user_defined_rules.map(&:approval_rule)).to eq(
                [
                  project_rule
                ])
            end
          end
        end
      end
    end

    context 'when approval rules are overwritten' do
      let!(:mr_rule) { create(:approval_merge_request_rule, merge_request: merge_request) }
      let!(:another_mr_rule) { create(:approval_merge_request_rule, merge_request: merge_request) }

      before do
        project.update!(disable_overriding_approvers_per_merge_request: false)
      end

      context 'when multiple approval rules is disabled' do
        it 'returns the first rule' do
          expect(subject.user_defined_rules.map(&:approval_rule)).to match_array(
            [
              mr_rule
            ])
        end
      end

      context 'when multiple approval rules is enabled' do
        before do
          stub_licensed_features(multiple_approval_rules: true)
        end

        it 'returns the rules as is' do
          expect(subject.user_defined_rules.map(&:approval_rule)).to match_array(
            [
              mr_rule,
              another_mr_rule
            ])
        end

        context 'and rules have source rules that are scoped by protected branches' do
          let(:source_rule) { create(:approval_project_rule, project: project) }
          let(:another_source_rule) { create(:approval_project_rule, project: project) }
          let(:protected_branch) { create(:protected_branch, project: project, name: 'stable-*') }
          let(:another_protected_branch) { create(:protected_branch, project: project, name: '*-stable') }

          before do
            merge_request.update!(target_branch: 'stable-1')
            source_rule.update!(protected_branches: [protected_branch])
            another_source_rule.update!(protected_branches: [another_protected_branch])

            mr_rule.update!(
              approval_project_rule: another_source_rule,
              name: another_source_rule.name,
              approvals_required: another_source_rule.approvals_required,
              users: another_source_rule.users,
              groups: another_source_rule.groups
            )

            another_mr_rule.update!(
              approval_project_rule: source_rule,
              name: source_rule.name,
              approvals_required: source_rule.approvals_required,
              users: source_rule.users,
              groups: source_rule.groups
            )
          end

          it 'returns the rules that are applicable to the merge request target branch' do
            expect(subject.user_defined_rules.map(&:approval_rule)).to eq(
              [
                another_mr_rule
              ])
          end

          context 'and target_branch is specified' do
            subject { described_class.new(merge_request, target_branch: 'v1-stable') }

            it 'returns the rules that are applicable to the specified target_branch' do
              expect(subject.user_defined_rules.map(&:approval_rule)).to eq([mr_rule])
            end
          end
        end
      end
    end
  end

  describe '#total_approvals_count' do
    let(:rule) { create_rule(approvals_required: 1, rule_type: :any_approver, users: [approver1]) }

    before do
      create(:approval, merge_request: merge_request, user: rule.users.first)
      create(:approval, merge_request: merge_request, user: approver2)
    end

    it 'returns the total number of approvals (required + optional)' do
      expect(subject.total_approvals_count).to eq(2)
    end
  end

  describe '#invalid_approvers_rules' do
    subject { merge_request.approval_state.invalid_approvers_rules }

    shared_examples 'invalid approver rules' do
      context 'when the rule is valid' do
        let!(:rule) { valid_rule }

        it 'does not include the rule' do
          approval_rules = subject.map(&:approval_rule)

          expect(approval_rules).not_to include(rule)
        end
      end

      context 'when invalid due to no approvers' do
        let!(:rule) { invalid_no_approvers_rule }

        it 'returns the rule' do
          approval_rules = subject.map(&:approval_rule)

          expect(approval_rules).to include(rule)
        end
      end

      context 'when invalid due to not enough approvers' do
        let!(:rule) { invalid_not_enough_approvers_rule }

        it 'returns the rule' do
          approval_rules = subject.map(&:approval_rule)

          expect(approval_rules).to include(rule)
        end
      end
    end

    context 'when the rule is code owner' do
      let(:valid_rule) { create(:code_owner_rule, merge_request: merge_request, users: create_list(:user, 1)) }
      let(:invalid_no_approvers_rule) { create(:code_owner_rule, merge_request: merge_request) }
      let(:invalid_not_enough_approvers_rule) do
        create(:code_owner_rule, merge_request: merge_request, users: create_list(:user, 1), approvals_required: 2)
      end

      before do
        stub_licensed_features(code_owner_approval_required: true)
        create(:protected_branch, project: project, name: merge_request.target_branch, code_owner_approval_required: true)
      end

      context 'when branch_requires_code_owner_approval is false' do
        let!(:rule) { create(:code_owner_rule, merge_request: merge_request) }

        it 'does not include the rule' do
          stub_licensed_features(code_owner_approval_required: false)

          approval_rules = subject.map(&:approval_rule)

          expect(approval_rules).not_to include(rule)
        end
      end

      include_examples 'invalid approver rules'
    end

    context 'when the rule is any_approver' do
      context 'when the rule has approvers' do
        let!(:rule) { create(:any_approver_rule, merge_request: merge_request, users: create_list(:user, 1)) }

        it 'is still valid and does not include the rule' do
          approval_rules = subject.map(&:approval_rule)

          expect(approval_rules).not_to include(rule)
        end
      end

      context 'when the rule has required approvals' do
        let!(:rule) { create(:any_approver_rule, merge_request: merge_request, approvals_required: 1) }

        it 'is still valid does not include the rule' do
          approval_rules = subject.map(&:approval_rule)

          expect(approval_rules).not_to include(rule)
        end
      end
    end

    context 'when the rule is approval_merge_request_rule' do
      let(:valid_rule) { create(:approval_merge_request_rule, merge_request: merge_request, users: create_list(:user, 1)) }
      let(:invalid_no_approvers_rule) { create(:approval_merge_request_rule, merge_request: merge_request, approvals_required: 1) }
      let(:invalid_not_enough_approvers_rule) do
        create(:approval_merge_request_rule, merge_request: merge_request, users: create_list(:user, 1), approvals_required: 2)
      end

      context 'when approvals required is 0' do
        let!(:rule) { create(:approval_merge_request_rule, merge_request: merge_request) }

        it 'does not include the rule' do
          approval_rules = subject.map(&:approval_rule)

          expect(approval_rules).not_to include(rule)
        end
      end

      include_examples 'invalid approver rules'
    end

    context 'when the rule is report_approver' do
      let(:valid_rule) { create(:report_approver_rule, merge_request: merge_request, users: create_list(:user, 1)) }
      let(:invalid_no_approvers_rule) { create(:report_approver_rule, merge_request: merge_request, approvals_required: 1) }
      let(:invalid_not_enough_approvers_rule) do
        create(:report_approver_rule, merge_request: merge_request, users: create_list(:user, 1), approvals_required: 2)
      end

      context 'when approvals required is 0' do
        let!(:rule) { create(:report_approver_rule, merge_request: merge_request) }

        it 'does not include the rule' do
          approval_rules = subject.map(&:approval_rule)

          expect(approval_rules).not_to include(rule)
        end
      end

      include_examples 'invalid approver rules'
    end
  end
end
