# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestPolicy, feature_category: :code_review_workflow do
  include ProjectForksHelper
  include AdminModeHelper

  let_it_be(:guest) { create(:user) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:admin) { create(:admin) }

  let_it_be(:fork_guest) { create(:user) }
  let_it_be(:fork_developer) { create(:user) }
  let_it_be(:fork_maintainer) { create(:user) }

  let(:project) { create(:project, :public) }
  let(:owner) { project.owner }
  let(:forked_project) { fork_project(project) }

  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let(:fork_merge_request) { create(:merge_request, author: fork_developer, source_project: forked_project, target_project: project) }

  before do
    project.add_guest(guest)
    project.add_developer(developer)
    project.add_maintainer(maintainer)
    project.add_reporter(reporter)

    forked_project.add_guest(fork_guest)
    forked_project.add_developer(fork_guest)
    forked_project.add_maintainer(fork_maintainer)
  end

  def policy_for(user)
    described_class.new(user, merge_request)
  end

  context 'for a merge request within the same project' do
    context 'when overwriting approvers is disabled on the project' do
      before do
        project.update!(disable_overriding_approvers_per_merge_request: true)
      end

      it 'does not allow anyone to update approvers' do
        expect(policy_for(guest)).to be_disallowed(:update_approvers)
        expect(policy_for(developer)).to be_disallowed(:update_approvers)
        expect(policy_for(maintainer)).to be_disallowed(:update_approvers)

        expect(policy_for(fork_guest)).to be_disallowed(:update_approvers)
        expect(policy_for(fork_developer)).to be_disallowed(:update_approvers)
        expect(policy_for(fork_maintainer)).to be_disallowed(:update_approvers)
      end
    end

    context 'when overwriting approvers is enabled on the project' do
      it 'allows only project developers and above to update the approvers' do
        expect(policy_for(developer)).to be_allowed(:update_approvers)
        expect(policy_for(maintainer)).to be_allowed(:update_approvers)

        expect(policy_for(guest)).to be_disallowed(:update_approvers)
        expect(policy_for(fork_guest)).to be_disallowed(:update_approvers)
        expect(policy_for(fork_developer)).to be_disallowed(:update_approvers)
        expect(policy_for(fork_maintainer)).to be_disallowed(:update_approvers)
      end
    end

    context 'allows project developers and above' do
      it 'to approve the merge request' do
        expect(policy_for(developer)).to be_allowed(:update_approvers)
        expect(policy_for(maintainer)).to be_allowed(:update_approvers)

        expect(policy_for(guest)).to be_disallowed(:update_approvers)
        expect(policy_for(fork_guest)).to be_disallowed(:update_approvers)
        expect(policy_for(fork_developer)).to be_disallowed(:update_approvers)
        expect(policy_for(fork_maintainer)).to be_disallowed(:update_approvers)
      end
    end
  end

  context 'for a merge request from a fork' do
    let(:merge_request) { fork_merge_request }

    context 'when overwriting approvers is disabled on the target project' do
      before do
        project.update!(disable_overriding_approvers_per_merge_request: true)
      end

      it 'does not allow anyone to update approvers' do
        expect(policy_for(guest)).to be_disallowed(:update_approvers)
        expect(policy_for(developer)).to be_disallowed(:update_approvers)
        expect(policy_for(maintainer)).to be_disallowed(:update_approvers)

        expect(policy_for(fork_guest)).to be_disallowed(:update_approvers)
        expect(policy_for(fork_developer)).to be_disallowed(:update_approvers)
        expect(policy_for(fork_maintainer)).to be_disallowed(:update_approvers)
      end
    end

    context 'when overwriting approvers is disabled on the source project' do
      before do
        forked_project.update!(disable_overriding_approvers_per_merge_request: true)
      end

      it 'has no effect - project developers and above, as well as the author, can update the approvers' do
        expect(policy_for(developer)).to be_allowed(:update_approvers)
        expect(policy_for(maintainer)).to be_allowed(:update_approvers)
        expect(policy_for(fork_developer)).to be_allowed(:update_approvers)

        expect(policy_for(guest)).to be_disallowed(:update_approvers)
        expect(policy_for(fork_guest)).to be_disallowed(:update_approvers)
        expect(policy_for(fork_maintainer)).to be_disallowed(:update_approvers)
      end
    end

    context 'when overwriting approvers is enabled on the target project' do
      it 'allows project developers and above, as well as the author, to update the approvers' do
        expect(policy_for(developer)).to be_allowed(:update_approvers)
        expect(policy_for(maintainer)).to be_allowed(:update_approvers)
        expect(policy_for(fork_developer)).to be_allowed(:update_approvers)

        expect(policy_for(guest)).to be_disallowed(:update_approvers)
        expect(policy_for(fork_guest)).to be_disallowed(:update_approvers)
        expect(policy_for(fork_maintainer)).to be_disallowed(:update_approvers)
      end
    end

    context 'allows project developers and above' do
      it 'to approve the merge requests' do
        expect(policy_for(developer)).to be_allowed(:update_approvers)
        expect(policy_for(maintainer)).to be_allowed(:update_approvers)
        expect(policy_for(fork_developer)).to be_allowed(:update_approvers)

        expect(policy_for(guest)).to be_disallowed(:update_approvers)
        expect(policy_for(fork_guest)).to be_disallowed(:update_approvers)
        expect(policy_for(fork_maintainer)).to be_disallowed(:update_approvers)
      end
    end
  end

  context 'for a merge request on a protected branch' do
    let(:branch_name) { 'feature' }
    let_it_be(:user) { create :user }
    let(:protected_branch) { create(:protected_branch, project: project, name: branch_name) }
    let_it_be(:approver_group) { create(:group) }

    let(:merge_request) { create(:merge_request, source_project: project, target_project: project, target_branch: branch_name) }

    before do
      project.add_reporter(user)
    end

    subject { described_class.new(user, merge_request) }

    context 'when the reporter nor the group is added' do
      specify do
        expect(subject).not_to be_allowed(:approve_merge_request)
      end
    end

    context 'when a group-level approval rule exists' do
      let(:approval_project_rule) { create :approval_project_rule, project: project, approvals_required: 1 }

      context 'when the merge request targets the protected branch' do
        before do
          approval_project_rule.protected_branches << protected_branch
          approval_project_rule.groups << approver_group
        end

        context 'when the reporter is not a group member' do
          specify do
            expect(subject).not_to be_allowed(:approve_merge_request)
          end
        end

        context 'when the reporter is a group member' do
          before do
            approver_group.add_reporter(user)
          end

          specify do
            expect(subject).to be_allowed(:approve_merge_request)
          end
        end
      end

      context 'when the reporter has permission for a different protected branch' do
        let(:protected_branch2) { create(:protected_branch, project: project, name: branch_name, code_owner_approval_required: true) }

        before do
          approval_project_rule.protected_branches << protected_branch2
          approval_project_rule.groups << approver_group
        end

        it 'does not allow approval of the merge request' do
          expect(subject).not_to be_allowed(:approve_merge_request)
        end
      end

      context 'when the protected branch name is a wildcard' do
        let(:wildcard_protected_branch) { create(:protected_branch, project: project, name: '*-stable') }

        before do
          approval_project_rule.protected_branches << wildcard_protected_branch
          approval_project_rule.groups << approver_group
          approver_group.add_reporter(user)
        end

        context 'when the reporter has permission for the wildcarded branch' do
          let(:branch_name) { '13-4-stable' }

          it 'does allows approval of the merge request' do
            expect(subject).to be_allowed(:approve_merge_request)
          end
        end

        context 'when the reporter does not have permission for the wildcarded branch' do
          let(:branch_name) { '13-4-pre' }

          it 'does allows approval of the merge request' do
            expect(subject).not_to be_allowed(:approve_merge_request)
          end
        end
      end
    end
  end

  context 'when checking for namespace in read only state' do
    context 'when namespace is in a read only state' do
      before do
        allow(merge_request.target_project.namespace).to receive(:read_only?).and_return(true)
      end

      it 'does not allow update_merge_request for all users including maintainer' do
        expect(policy_for(maintainer)).to be_disallowed(:update_merge_request)
      end

      it 'does allow approval of the merge request' do
        expect(policy_for(developer)).to be_allowed(:approve_merge_request)
      end
    end

    context 'when namespace is not in a read only state' do
      before do
        allow(merge_request.target_project.namespace).to receive(:read_only?).and_return(false)
      end

      it 'does not lock basic policies for any user' do
        expect(policy_for(maintainer)).to be_allowed(
          :approve_merge_request,
          :update_merge_request,
          :reopen_merge_request,
          :create_note,
          :resolve_note
        )
      end
    end
  end

  shared_examples 'external_status_check_access' do
    using RSpec::Parameterized::TableSyntax

    subject { policy_for(current_user) }

    where(:role, :licensed, :allowed) do
      :guest      | false  | false
      :reporter   | false  | false
      :developer  | false  | false
      :maintainer | false  | false
      :owner      | false  | false
      :admin      | false  | false
      :guest      | true   | false
      :reporter   | true   | false
      :developer  | true   | true
      :maintainer | true   | true
      :owner      | true   | true
      :admin      | true   | true
    end

    with_them do
      let(:current_user) { public_send(role) }

      before do
        stub_licensed_features(external_status_checks: licensed)
        enable_admin_mode!(current_user) if role.eql?(:admin)
      end

      it { is_expected.to(allowed ? be_allowed(policy) : be_disallowed(policy)) }
    end
  end

  describe 'retry_failed_status_checks' do
    let(:policy) { :retry_failed_status_checks }

    it_behaves_like 'external_status_check_access'
  end

  describe 'provide_status_check_response' do
    let(:policy) { :provide_status_check_response }

    it_behaves_like 'external_status_check_access'
  end

  describe 'create_merge_request_approval_rules' do
    using RSpec::Parameterized::TableSyntax

    let(:policy) { :create_merge_request_approval_rules }
    let(:current_user) { owner }

    subject { policy_for(current_user) }

    where(:coverage_license_enabled, :report_approver_license_enabled, :allowed) do
      false | false | false
      true  | true  | true
      false | true  | true
      true  | false | true
    end

    with_them do
      before do
        stub_licensed_features(
          coverage_check_approval_rule: coverage_license_enabled,
          report_approver_rules: report_approver_license_enabled
        )
      end

      it { is_expected.to(allowed ? be_allowed(policy) : be_disallowed(policy)) }
    end
  end

  describe 'create_visual_review_note rules' do
    let(:non_member) { build(:user) }
    let(:unauthenticated) { nil }

    using RSpec::Parameterized::TableSyntax

    context 'when the merge request is within the same project' do
      where(:role, :merge_request_discussion_locked?, :project_archived?, :allowed) do
        :guest      | true | false | false
        :developer  | true | false | false
        :maintainer | true | false | false
        :reporter   | true | false | false
        :admin      | true | false | false
        :non_member | true | false | false

        :guest      | false | false | true
        :developer  | false | false | true
        :maintainer | false | false | true
        :reporter   | false | false | true
        :admin      | false | false | true

        :guest      | true | true | false
        :developer  | true | true | false
        :maintainer | true | true | false
        :reporter   | true | true | false
        :admin      | true | true | false
        :non_member | true | true | false

        :guest      | false | true | false
        :developer  | false | true | false
        :maintainer | false | true | false
        :reporter   | false | true | false
        :admin      | false | true | false
      end

      with_them do
        let(:policy) { :create_visual_review_note }
        let(:user) { public_send(role) }
        let(:merge_request) { build(:merge_request, source_project: project, target_project: project) }

        subject(:policy) { policy_for(user) }

        before do
          merge_request.update_attribute(:discussion_locked, true) if merge_request_discussion_locked?
          ::Projects::UpdateService.new(project, user, archived: true).execute if project_archived?
        end

        it { expect(policy.allowed?(:create_visual_review_note)).to be(allowed) }
      end
    end
  end
end
