# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GlobalPolicy, feature_category: :shared do
  include ExternalAuthorizationServiceHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:admin) { create(:admin) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:user) { create(:user) }

  subject { described_class.new(current_user, [user]) }

  describe 'reading operations dashboard' do
    context 'when licensed' do
      before do
        stub_licensed_features(operations_dashboard: true)
      end

      it { is_expected.to be_allowed(:read_operations_dashboard) }

      context 'and the user is not logged in' do
        let(:current_user) { nil }

        it { is_expected.to be_disallowed(:read_operations_dashboard) }
      end
    end

    context 'when unlicensed' do
      before do
        stub_licensed_features(operations_dashboard: false)
      end

      it { is_expected.to be_disallowed(:read_operations_dashboard) }
    end
  end

  describe 'reading workspaces' do
    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(remote_development_feature_flag: false)
      end

      it { is_expected.to be_disallowed(:read_workspace) }
    end

    context 'when licensed' do
      before do
        stub_licensed_features(remote_development: true)
      end

      it { is_expected.to be_allowed(:read_workspace) }

      context 'and the user is not logged in' do
        let(:current_user) { nil }

        it { is_expected.to be_disallowed(:read_workspace) }
      end
    end

    context 'when unlicensed' do
      before do
        stub_licensed_features(remote_development: false)
      end

      it { is_expected.to be_disallowed(:read_workspace) }
    end
  end

  it { is_expected.to be_disallowed(:read_licenses) }
  it { is_expected.to be_disallowed(:destroy_licenses) }
  it { is_expected.to be_disallowed(:read_all_geo) }
  it { is_expected.to be_disallowed(:manage_subscription) }

  context 'when admin mode enabled', :enable_admin_mode do
    it { expect(described_class.new(admin, [user])).to be_allowed(:read_licenses) }
    it { expect(described_class.new(admin, [user])).to be_allowed(:destroy_licenses) }
    it { expect(described_class.new(admin, [user])).to be_allowed(:read_all_geo) }
    it { expect(described_class.new(admin, [user])).to be_allowed(:manage_subscription) }
  end

  context 'when admin mode disabled' do
    it { expect(described_class.new(admin, [user])).to be_disallowed(:read_licenses) }
    it { expect(described_class.new(admin, [user])).to be_disallowed(:destroy_licenses) }
    it { expect(described_class.new(admin, [user])).to be_disallowed(:read_all_geo) }
    it { expect(described_class.new(admin, [user])).to be_disallowed(:manage_subscription) }
  end

  shared_examples 'analytics policy' do |action|
    context 'anonymous user' do
      let(:current_user) { nil }

      it 'is not allowed' do
        is_expected.to be_disallowed(action)
      end
    end

    context 'authenticated user' do
      it 'is allowed' do
        is_expected.to be_allowed(action)
      end
    end
  end

  describe 'view_productivity_analytics' do
    include_examples 'analytics policy', :view_productivity_analytics
  end

  describe 'update_max_pages_size' do
    context 'when feature is enabled' do
      before do
        stub_licensed_features(pages_size_limit: true)
      end

      it { is_expected.to be_disallowed(:update_max_pages_size) }

      context 'when admin mode enabled', :enable_admin_mode do
        it { expect(described_class.new(admin, [user])).to be_allowed(:update_max_pages_size) }
      end

      context 'when admin mode disabled' do
        it { expect(described_class.new(admin, [user])).to be_disallowed(:update_max_pages_size) }
      end
    end

    it { expect(described_class.new(admin, [user])).to be_disallowed(:update_max_pages_size) }
  end

  describe 'create_group_with_default_branch_protection' do
    context 'for an admin' do
      let(:current_user) { admin }

      context 'when the `default_branch_protection_restriction_in_groups` feature is available' do
        before do
          stub_licensed_features(default_branch_protection_restriction_in_groups: true)
        end

        context 'when the setting `group_owners_can_manage_default_branch_protection` is enabled' do
          before do
            stub_ee_application_setting(group_owners_can_manage_default_branch_protection: true)
          end

          it { is_expected.to be_allowed(:create_group_with_default_branch_protection) }
        end

        context 'when the setting `group_owners_can_manage_default_branch_protection` is disabled' do
          before do
            stub_ee_application_setting(group_owners_can_manage_default_branch_protection: false)
          end

          context 'when admin mode is enabled', :enable_admin_mode do
            it { is_expected.to be_allowed(:create_group_with_default_branch_protection) }
          end

          context 'when admin mode is disabled' do
            it { is_expected.to be_disallowed(:create_group_with_default_branch_protection) }
          end
        end
      end

      context 'when the `default_branch_protection_restriction_in_groups` feature is not available' do
        before do
          stub_licensed_features(default_branch_protection_restriction_in_groups: false)
        end

        context 'when the setting `group_owners_can_manage_default_branch_protection` is enabled' do
          before do
            stub_ee_application_setting(group_owners_can_manage_default_branch_protection: true)
          end

          it { is_expected.to be_allowed(:create_group_with_default_branch_protection) }
        end

        context 'when the setting `group_owners_can_manage_default_branch_protection` is disabled' do
          before do
            stub_ee_application_setting(group_owners_can_manage_default_branch_protection: false)
          end

          it { is_expected.to be_allowed(:create_group_with_default_branch_protection) }
        end
      end
    end

    context 'for a normal user' do
      let(:current_user) { create(:user) }

      context 'when the `default_branch_protection_restriction_in_groups` feature is available' do
        before do
          stub_licensed_features(default_branch_protection_restriction_in_groups: true)
        end

        context 'when the setting `group_owners_can_manage_default_branch_protection` is enabled' do
          before do
            stub_ee_application_setting(group_owners_can_manage_default_branch_protection: true)
          end

          it { is_expected.to be_allowed(:create_group_with_default_branch_protection) }
        end

        context 'when the setting `group_owners_can_manage_default_branch_protection` is disabled' do
          before do
            stub_ee_application_setting(group_owners_can_manage_default_branch_protection: false)
          end

          it { is_expected.to be_disallowed(:create_group_with_default_branch_protection) }
        end
      end

      context 'when the `default_branch_protection_restriction_in_groups` feature is not available' do
        before do
          stub_licensed_features(default_branch_protection_restriction_in_groups: false)
        end

        context 'when the setting `group_owners_can_manage_default_branch_protection` is enabled' do
          before do
            stub_ee_application_setting(group_owners_can_manage_default_branch_protection: true)
          end

          it { is_expected.to be_allowed(:create_group_with_default_branch_protection) }
        end

        context 'when the setting `group_owners_can_manage_default_branch_protection` is disabled' do
          before do
            stub_ee_application_setting(group_owners_can_manage_default_branch_protection: false)
          end

          it { is_expected.to be_allowed(:create_group_with_default_branch_protection) }
        end
      end
    end
  end

  describe 'list_removable_projects' do
    context 'when user is an admin', :enable_admin_mode do
      let_it_be(:current_user) { admin }

      before do
        stub_licensed_features(adjourned_deletion_for_projects_and_groups: licensed?)
      end

      context 'when licensed feature is enabled' do
        let(:licensed?) { true }

        it { is_expected.to be_allowed(:list_removable_projects) }
      end

      context 'when licensed feature is not enabled' do
        let(:licensed?) { false }

        it { is_expected.to be_disallowed(:list_removable_projects) }
      end
    end

    context 'when user is a normal user' do
      let_it_be(:current_user) { create(:user) }

      before do
        stub_licensed_features(adjourned_deletion_for_projects_and_groups: licensed?)
      end

      context 'when licensed feature is enabled' do
        let(:licensed?) { true }

        it { is_expected.to be_allowed(:list_removable_projects) }
      end

      context 'when licensed feature is not enabled' do
        let(:licensed?) { false }

        it { is_expected.to be_disallowed(:list_removable_projects) }
      end
    end
  end

  describe ':export_user_permissions', :enable_admin_mode do
    let(:policy) { :export_user_permissions }

    let_it_be(:admin) { build_stubbed(:admin) }
    let_it_be(:guest) { build_stubbed(:user) }

    where(:role, :licensed, :allowed) do
      :admin | true | true
      :admin | false | false
      :guest | true | false
      :guest | false | false
    end

    with_them do
      let(:current_user) { public_send(role) }

      before do
        stub_licensed_features(export_user_permissions: licensed)
      end

      it { is_expected.to(allowed ? be_allowed(policy) : be_disallowed(policy)) }
    end
  end

  describe 'create_group_via_api' do
    let(:policy) { :create_group_via_api }

    context 'on .com' do
      before do
        allow(::Gitlab).to receive(:com?).and_return(true)
      end

      context 'when feature is enabled' do
        before do
          stub_feature_flags(top_level_group_creation_enabled: true)
        end

        it { is_expected.to be_allowed(policy) }
      end

      context 'when feature is disabled' do
        before do
          stub_feature_flags(top_level_group_creation_enabled: false)
        end

        it { is_expected.to be_disallowed(policy) }
      end
    end

    context 'on self-managed' do
      context 'when feature is enabled' do
        before do
          stub_feature_flags(top_level_group_creation_enabled: true)
        end

        it { is_expected.to be_allowed(policy) }
      end

      context 'when feature is disabled' do
        before do
          stub_feature_flags(top_level_group_creation_enabled: false)
        end

        it { is_expected.to be_allowed(policy) }
      end
    end
  end

  describe ':view_instance_devops_adoption & :manage_devops_adoption_namespaces', :enable_admin_mode do
    let(:current_user) { admin }

    context 'when license does not include the feature' do
      before do
        stub_licensed_features(instance_level_devops_adoption: false)
      end

      it { is_expected.to be_disallowed(:view_instance_devops_adoption, :manage_devops_adoption_namespaces) }
    end

    context 'when feature is enabled and license include the feature' do
      before do
        stub_licensed_features(instance_level_devops_adoption: true)
      end

      it { is_expected.to be_allowed(:view_instance_devops_adoption, :manage_devops_adoption_namespaces) }

      context 'for non-admins' do
        let(:current_user) { user }

        it { is_expected.to be_disallowed(:view_instance_devops_adoption, :manage_devops_adoption_namespaces) }
      end
    end
  end

  describe 'read_jobs_statistics' do
    context 'when feature is enabled' do
      before do
        stub_licensed_features(runner_performance_insights: true)
      end

      it { is_expected.to be_disallowed(:read_jobs_statistics) }

      context 'when admin mode enabled', :enable_admin_mode do
        it { expect(described_class.new(admin, [user])).to be_allowed(:read_jobs_statistics) }
      end

      context 'when admin mode disabled' do
        it { expect(described_class.new(admin, [user])).to be_disallowed(:read_jobs_statistics) }
      end
    end

    context 'when feature is disabled' do
      before do
        stub_licensed_features(runner_performance_insights: false)
      end

      context 'when admin mode enabled', :enable_admin_mode do
        it { expect(described_class.new(admin, [user])).to be_disallowed(:read_jobs_statistics) }
      end
    end
  end

  describe 'read_runner_upgrade_status' do
    it { is_expected.to be_disallowed(:read_runner_upgrade_status) }

    context 'when runner_upgrade_management is available' do
      before do
        stub_licensed_features(runner_upgrade_management: true)
      end

      it { is_expected.to be_allowed(:read_runner_upgrade_status) }
    end

    context 'when user has paid namespace' do
      before do
        allow(Gitlab).to receive(:com?).and_return true
        group = create(:group_with_plan, plan: :ultimate_plan)
        group.add_maintainer(user)
      end

      it { expect(described_class.new(user, nil)).to be_allowed(:read_runner_upgrade_status) }
    end
  end

  describe 'admin_service_accounts' do
    subject { described_class.new(admin, [user]) }

    it { is_expected.to be_disallowed(:admin_service_accounts) }

    context 'when feature is enabled' do
      before do
        stub_licensed_features(service_accounts: true)
      end

      context 'when admin mode enabled', :enable_admin_mode do
        it { is_expected.to be_allowed(:admin_service_accounts) }
      end

      context 'when admin mode disabled' do
        it { is_expected.to be_disallowed(:admin_service_accounts) }
      end
    end
  end

  describe 'admin_instance_external_audit_events' do
    let_it_be(:admin) { create(:admin) }
    let_it_be(:user) { create(:user) }

    shared_examples 'admin external events is not allowed' do
      context 'when user is instance admin' do
        context 'when admin mode enabled', :enable_admin_mode do
          it { expect(described_class.new(admin, nil)).to be_disallowed(:admin_instance_external_audit_events) }
        end

        context 'when admin mode disabled' do
          it { expect(described_class.new(admin, nil)).to be_disallowed(:admin_instance_external_audit_events) }
        end
      end

      context 'when user is not instance admin' do
        it { expect(described_class.new(user, nil)).to be_disallowed(:admin_instance_external_audit_events) }
      end
    end

    context 'when licence is enabled' do
      before do
        stub_licensed_features(external_audit_events: true)
      end

      context 'when feature flag ff_external_audit_events is enabled' do
        context 'when user is instance admin' do
          context 'when admin mode enabled', :enable_admin_mode do
            it { expect(described_class.new(admin, nil)).to be_allowed(:admin_instance_external_audit_events) }
          end

          context 'when admin mode disabled' do
            it { expect(described_class.new(admin, nil)).to be_disallowed(:admin_instance_external_audit_events) }
          end
        end

        context 'when user is not instance admin' do
          it { expect(described_class.new(user, nil)).to be_disallowed(:admin_instance_external_audit_events) }
        end
      end

      context 'when feature flag ff_external_audit_events is disabled' do
        before do
          stub_feature_flags(ff_external_audit_events: false)
        end

        it_behaves_like 'admin external events is not allowed'
      end
    end

    context 'when licence is not enabled' do
      context 'when feature flag ff_external_audit_events is enabled' do
        it_behaves_like 'admin external events is not allowed'
      end

      context 'when feature flag ff_external_audit_events is disabled' do
        before do
          stub_feature_flags(ff_external_audit_events: false)
        end

        it_behaves_like 'admin external events is not allowed'
      end
    end
  end

  describe 'access_code_suggestions' do
    let(:policy) { :access_code_suggestions }

    let_it_be_with_reload(:current_user) { create(:user) }
    let_it_be_with_reload(:first_group) { create(:group) }
    let_it_be_with_reload(:second_group) { create(:group) }

    context 'when on .org or .com' do
      where(:user_code_suggestions_setting, :group_1_cs_setting, :group_2_cs_setting, :code_suggestions_matcher) do
        false | false | false | be_disallowed(:access_code_suggestions)
        true  | false | false | be_disallowed(:access_code_suggestions)
        false | false | true  | be_disallowed(:access_code_suggestions)
        true  | false | true  | be_disallowed(:access_code_suggestions)
        false | true  | true  | be_disallowed(:access_code_suggestions)
        true  | true  | true  | be_allowed(:access_code_suggestions)
      end

      with_them do
        before do
          allow(::Gitlab).to receive(:org_or_com?).and_return(true)

          current_user.update_attribute(:code_suggestions, user_code_suggestions_setting)
          first_group.update_attribute(:code_suggestions, group_1_cs_setting)
          second_group.update_attribute(:code_suggestions, group_2_cs_setting)

          first_group.add_owner(current_user)
          second_group.add_owner(current_user)
        end

        it { is_expected.to code_suggestions_matcher }
      end
    end

    context 'when not on .org or .com' do
      where(:instance_level_code_suggestions_enabled, :ai_access_token, :code_suggestions_matcher) do
        false | nil                  | be_disallowed(:access_code_suggestions)
        true  | nil                  | be_disallowed(:access_code_suggestions)
        false | 'glpat-access_token' | be_disallowed(:access_code_suggestions)
        true  | 'glpat-access_token' | be_allowed(:access_code_suggestions)
      end

      with_them do
        before do
          allow(::Gitlab).to receive(:org_or_com?).and_return(false)
          stub_ee_application_setting(instance_level_code_suggestions_enabled: instance_level_code_suggestions_enabled)
          stub_ee_application_setting(ai_access_token: ai_access_token)
        end

        it { is_expected.to code_suggestions_matcher }
      end
    end
  end
end
