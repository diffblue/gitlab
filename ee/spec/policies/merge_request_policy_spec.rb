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

  describe "summarize_draft_code_review", :saas do
    let_it_be(:reviewer) { create(:user) }
    let_it_be(:ultimate_group) do
      create(
        :group_with_plan,
        :public,
        plan: :ultimate_plan,
        third_party_ai_features_enabled: true,
        experiment_features_enabled: true
      )
    end

    let_it_be(:ultimate_project) { create(:project, :public, group: ultimate_group) }
    let_it_be(:merge_request) do
      create(
        :merge_request,
        source_project: ultimate_project,
        target_project: ultimate_project,
        author: reviewer
      )
    end

    let(:policy_under_test) { described_class.new(reviewer, merge_request) }

    subject { policy_for(reviewer) }

    before do
      stub_ee_application_setting(should_check_namespace_plan: true)
      stub_licensed_features(
        summarize_my_mr_code_review: true,
        ai_features: true
      )

      project.add_maintainer(reviewer)
      ultimate_group.namespace_settings.update!(
        third_party_ai_features_enabled: true,
        experiment_features_enabled: true
      )
    end

    context "when all settings enabled and restrictions are fulfilled" do
      it "allows" do
        expect(policy_under_test.allowed?(:summarize_draft_code_review)).to be(true)
      end
    end

    context "when namespace isn't available" do
      it "does not allow" do
        expect(merge_request.project.group).to receive(:root_ancestor).and_return(nil)
        expect(policy_under_test.allowed?(:summarize_draft_code_review)).to be(false)
      end
    end

    context "when summarize_my_code_review feature flag is disabled" do
      before do
        stub_feature_flags(summarize_my_code_review: false)
      end

      it "does not allow" do
        expect(policy_under_test.allowed?(:summarize_draft_code_review)).to be(false)
      end
    end

    context "when namespace isn't a group namespace" do
      it "does not allow" do
        expect(merge_request.project.group.root_ancestor).to receive(:group_namespace?).and_return(false)
        expect(policy_under_test.allowed?(:summarize_draft_code_review)).to be(false)
      end
    end

    context "when summarize_my_mr_code_review licensed feature is disabled" do
      before do
        stub_licensed_features(summarize_my_mr_code_review: false)
      end

      it "does not allow" do
        expect(policy_under_test.allowed?(:summarize_draft_code_review)).to be(false)
      end
    end

    context "when ::Gitlab::Llm::StageCheck.available? returns false" do
      it "does not allow" do
        expect(::Gitlab::Llm::StageCheck).to receive(:available?).and_return(false)
        expect(policy_under_test.allowed?(:summarize_draft_code_review)).to be(false)
      end
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

  describe 'summarize_submitted_review policy', :saas do
    let_it_be(:namespace) { create(:group_with_plan, plan: :ultimate_plan) }
    let_it_be(:project) { create(:project, group: namespace) }
    let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
    let_it_be(:current_user) { developer }

    subject { described_class.new(current_user, merge_request) }

    before do
      stub_ee_application_setting(should_check_namespace_plan: true)

      stub_licensed_features(
        summarize_submitted_review: true,
        ai_features: true
      )

      stub_feature_flags(
        openai_experimentation: true,
        automatically_summarize_mr_review: true
      )

      namespace.namespace_settings.update!(
        experiment_features_enabled: true,
        third_party_ai_features_enabled: true
      )
    end

    it { is_expected.to be_allowed(:summarize_submitted_review) }

    context 'when global AI feature flag is disabled' do
      before do
        stub_feature_flags(openai_experimentation: false)
      end

      it { is_expected.to be_disallowed(:summarize_submitted_review) }
    end

    context 'when automatically_summarize_mr_review feature flag is disabled' do
      before do
        stub_feature_flags(
          openai_experimentation: true,
          automatically_summarize_mr_review: false
        )
      end

      it { is_expected.to be_disallowed(:summarize_submitted_review) }
    end

    context 'when license is not set' do
      before do
        stub_licensed_features(summarize_submitted_review: false)
      end

      it { is_expected.to be_disallowed(:summarize_submitted_review) }
    end

    context 'when experiment features are disabled' do
      before do
        namespace.namespace_settings.update!(experiment_features_enabled: false)
      end

      it { is_expected.to be_disallowed(:summarize_submitted_review) }
    end

    context 'when third party ai features are disabled' do
      before do
        namespace.namespace_settings.update!(third_party_ai_features_enabled: false)
      end

      it { is_expected.to be_disallowed(:summarize_submitted_review) }
    end

    context 'when user cannot read merge request' do
      let(:current_user) { guest }

      it { is_expected.to be_disallowed(:summarize_submitted_review) }
    end
  end

  describe "Custom roles `admin_merge_request` ability" do
    let_it_be(:project) { create(:project, :public, :in_group) }
    let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

    subject { described_class.new(guest, merge_request) }

    context 'when the `custom_roles` feature is enabled' do
      before do
        stub_licensed_features(custom_roles: true)
      end

      context 'when the user is a member of a custom role with `admin_merge_request` enabled' do
        let_it_be(:custom_role) { create(:member_role, :guest, namespace: project.group, admin_merge_request: true) }
        let_it_be(:project_member) { create(:project_member, :guest, member_role: custom_role, project: project, user: guest) }

        it 'enables the `approve_merge_request` ability' do
          expect(subject).to be_allowed(:approve_merge_request)
        end
      end

      context 'when the user is a member of a custom role with `admin_merge_request` disabled' do
        let_it_be(:custom_role) { create(:member_role, :guest, namespace: project.group, admin_merge_request: false) }
        let_it_be(:project_member) { create(:project_member, :guest, member_role: custom_role, project: project, user: guest) }

        it 'disables the `approve_merge_request` ability' do
          expect(subject).to be_disallowed(:approve_merge_request)
        end
      end
    end

    context 'when the `custom_roles` feature is disabled' do
      before do
        stub_licensed_features(custom_roles: false)
      end

      it 'disables the `approve_merge_request` ability' do
        expect(subject).to be_disallowed(:approve_merge_request)
      end
    end
  end

  describe 'summarize_merge_request policy', :saas do
    let_it_be(:namespace) { create(:group_with_plan, plan: :ultimate_plan) }
    let_it_be(:project) { create(:project, group: namespace) }
    let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
    let_it_be(:current_user) { developer }

    subject { described_class.new(current_user, merge_request) }

    before do
      stub_ee_application_setting(should_check_namespace_plan: true)

      stub_licensed_features(
        summarize_mr_changes: true,
        ai_features: true
      )

      stub_feature_flags(
        openai_experimentation: true,
        summarize_diff_automatically: true
      )

      namespace.namespace_settings.update!(
        experiment_features_enabled: true,
        third_party_ai_features_enabled: true
      )
    end

    it { is_expected.to be_allowed(:summarize_merge_request) }

    context 'when global AI feature flag is disabled' do
      before do
        stub_feature_flags(openai_experimentation: false)
      end

      it { is_expected.to be_disallowed(:summarize_merge_request) }
    end

    context 'when summarize_diff_automatically feature flag is disabled' do
      before do
        stub_feature_flags(
          openai_experimentation: true,
          summarize_diff_automatically: false
        )
      end

      it { is_expected.to be_disallowed(:summarize_merge_request) }
    end

    context 'when license is not set' do
      before do
        stub_licensed_features(summarize_mr_changes: false)
      end

      it { is_expected.to be_disallowed(:summarize_merge_request) }
    end

    context 'when experiment features are disabled' do
      before do
        namespace.namespace_settings.update!(experiment_features_enabled: false)
      end

      it { is_expected.to be_disallowed(:summarize_merge_request) }
    end

    context 'when third party ai features are disabled' do
      before do
        namespace.namespace_settings.update!(third_party_ai_features_enabled: false)
      end

      it { is_expected.to be_disallowed(:summarize_merge_request) }
    end

    context 'when user cannot generate_diff_summary' do
      let(:current_user) { guest }

      it { is_expected.to be_disallowed(:summarize_merge_request) }
    end
  end
end
