# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupPolicy, feature_category: :subgroups do
  include AdminModeHelper

  include_context 'GroupPolicy context'
  # Can't move to GroupPolicy context because auditor trait is not present
  # outside of EE context and foss-impact will fail on this
  let_it_be(:auditor) { create(:user, :auditor) }

  let(:epic_rules) do
    %i(read_epic create_epic admin_epic destroy_epic read_confidential_epic
       read_epic_board read_epic_board_list admin_epic_board
       admin_epic_board_list)
  end

  let(:auditor_permissions) do
    %i[
      read_group
      read_group_security_dashboard
      read_cluster
      read_group_runners
      read_billing
      read_container_image
    ]
  end

  context 'when epics feature is disabled' do
    let(:current_user) { owner }

    it { is_expected.to be_disallowed(*epic_rules) }
  end

  context 'when epics feature is enabled' do
    before do
      stub_licensed_features(epics: true)
    end

    context 'when user is owner' do
      let(:current_user) { owner }

      it { is_expected.to be_allowed(*epic_rules) }
    end

    context 'when user is admin' do
      let(:current_user) { admin }

      context 'when admin mode is enabled', :enable_admin_mode do
        it { is_expected.to be_allowed(*epic_rules) }
      end

      context 'when admin mode is disabled' do
        it { is_expected.to be_disallowed(*epic_rules) }
      end
    end

    context 'when user is maintainer' do
      let(:current_user) { maintainer }

      it { is_expected.to be_allowed(*(epic_rules - [:destroy_epic])) }
      it { is_expected.to be_disallowed(:destroy_epic) }
    end

    context 'when user is developer' do
      let(:current_user) { developer }

      it { is_expected.to be_allowed(*(epic_rules - [:destroy_epic])) }
      it { is_expected.to be_disallowed(:destroy_epic) }
    end

    context 'when user is reporter' do
      let(:current_user) { reporter }

      it { is_expected.to be_allowed(*(epic_rules - [:destroy_epic])) }
      it { is_expected.to be_disallowed(:destroy_epic) }
    end

    context 'when user is guest' do
      let(:current_user) { guest }

      it { is_expected.to be_allowed(:read_epic, :read_epic_board, :list_subgroup_epics) }
      it { is_expected.to be_disallowed(*(epic_rules - [:read_epic, :read_epic_board, :read_epic_board_list])) }
    end

    context 'when user is support bot' do
      let_it_be(:current_user) { User.support_bot }

      before do
        allow(Gitlab::ServiceDesk).to receive(:supported?).and_return(true)
      end

      context 'when group has at least one project with service desk enabled' do
        let_it_be(:project_with_service_desk) do
          create(:project, group: group, service_desk_enabled: true)
        end

        it { is_expected.to be_allowed(:read_epic, :read_epic_iid) }
        it { is_expected.to be_disallowed(*(epic_rules - [:read_epic, :read_epic_iid])) }
      end

      context 'when group does not have projects with service desk enabled' do
        let_it_be(:project_without_service_desk) do
          create(:project, group: group, service_desk_enabled: false)
        end

        it { is_expected.to be_disallowed(*epic_rules) }
      end
    end

    context 'when user is not member' do
      let(:current_user) { create(:user) }

      it { is_expected.to be_disallowed(*epic_rules) }
    end

    context 'when user is anonymous' do
      let(:current_user) { nil }

      it { is_expected.to be_disallowed(*epic_rules) }
    end
  end

  context 'when iterations feature is disabled' do
    let(:current_user) { owner }

    before do
      stub_licensed_features(iterations: false)
    end

    it { is_expected.to be_disallowed(:read_iteration, :create_iteration, :admin_iteration, :create_iteration_cadence, :admin_iteration_cadence) }
  end

  context 'when iterations feature is enabled' do
    before do
      stub_licensed_features(iterations: true)
    end

    context 'when user is a developer' do
      let(:current_user) { developer }

      it { is_expected.to be_allowed(:read_iteration, :create_iteration, :admin_iteration, :read_iteration_cadence, :create_iteration_cadence, :admin_iteration_cadence) }
    end

    context 'when user is a guest' do
      let(:current_user) { guest }

      it { is_expected.to be_allowed(:read_iteration, :read_iteration_cadence) }
      it { is_expected.to be_disallowed(:create_iteration, :admin_iteration, :create_iteration_cadence, :admin_iteration_cadence) }
    end

    context 'when user is logged out' do
      let(:current_user) { nil }

      it { is_expected.to be_disallowed(:read_iteration, :create_iteration, :admin_iteration, :create_iteration_cadence) }
    end

    context 'when project is private' do
      let(:group) { create(:group, :public, :owner_subgroup_creation_only) }

      context 'when user is logged out' do
        let(:current_user) { nil }

        it { is_expected.to be_allowed(:read_iteration, :read_iteration_cadence) }
        it { is_expected.to be_disallowed(:create_iteration, :admin_iteration, :create_iteration_cadence, :admin_iteration_cadence) }
      end
    end
  end

  context 'when cluster deployments is available' do
    let(:current_user) { maintainer }

    before do
      stub_licensed_features(cluster_deployments: true)
    end

    it { is_expected.to be_allowed(:read_cluster_environments) }
  end

  context 'when cluster deployments is not available' do
    let(:current_user) { maintainer }

    before do
      stub_licensed_features(cluster_deployments: false)
    end

    it { is_expected.not_to be_allowed(:read_cluster_environments) }
  end

  context 'when contribution analytics is available' do
    let(:current_user) { developer }

    before do
      stub_licensed_features(contribution_analytics: true)
    end

    context 'when signed in user is a member of the group' do
      it { is_expected.to be_allowed(:read_group_contribution_analytics) }
    end

    describe 'when user is not a member of the group' do
      let(:current_user) { non_group_member }
      let(:private_group) { create(:group, :private) }

      subject { described_class.new(non_group_member, private_group) }

      context 'when user is not invited to any of the group projects' do
        it { is_expected.not_to be_allowed(:read_group_contribution_analytics) }
      end

      context 'when user is invited to a group project, but not to the group' do
        let(:private_project) { create(:project, :private, group: private_group) }

        before do
          private_project.add_guest(non_group_member)
        end

        it { is_expected.not_to be_allowed(:read_group_contribution_analytics) }
      end

      context 'when user has an auditor role' do
        before do
          allow(current_user).to receive(:auditor?).and_return(true)
        end

        it { is_expected.to be_allowed(:read_group_contribution_analytics) }
      end
    end
  end

  context 'when contribution analytics is not available' do
    let(:current_user) { developer }

    before do
      stub_licensed_features(contribution_analytics: false)
    end

    it { is_expected.not_to be_allowed(:read_group_contribution_analytics) }
  end

  context 'when dora4 analytics is available' do
    before do
      stub_licensed_features(dora4_analytics: true)
    end

    context 'when the user is a developer' do
      let(:current_user) { developer }

      it { is_expected.to be_allowed(:read_dora4_analytics) }
    end

    context 'when the user is an auditor' do
      let(:current_user) { auditor }

      it { is_expected.to be_allowed(:read_dora4_analytics) }
    end

    context 'when the user is an admin', :enable_admin_mode do
      let(:current_user) { admin }

      it { is_expected.to be_allowed(:read_dora4_analytics) }
    end
  end

  context 'when dora4 analytics is not available' do
    let(:current_user) { developer }

    before do
      stub_licensed_features(dora4_analytics: false)
    end

    it { is_expected.not_to be_allowed(:read_dora4_analytics) }
  end

  context 'export group memberships' do
    let(:current_user) { owner }

    context 'when exporting user permissions is not available' do
      before do
        stub_licensed_features(export_user_permissions: false)
      end

      it { is_expected.not_to be_allowed(:export_group_memberships) }
    end

    context 'when exporting user permissions is available' do
      before do
        stub_licensed_features(export_user_permissions: true)
      end

      it { is_expected.to be_allowed(:export_group_memberships) }
    end
  end

  context 'when group activity analytics is available' do
    let(:current_user) { developer }

    before do
      stub_licensed_features(group_activity_analytics: true)
    end

    it { is_expected.to be_allowed(:read_group_activity_analytics) }
  end

  context 'when group activity analytics is not available' do
    let(:current_user) { developer }

    before do
      stub_licensed_features(group_activity_analytics: false)
    end

    it { is_expected.not_to be_allowed(:read_group_activity_analytics) }
  end

  context 'group CI/CD analytics' do
    context 'when group CI/CD analytics is available' do
      before do
        stub_licensed_features(group_ci_cd_analytics: true)
      end

      context 'when the user has at least reporter permissions' do
        let(:current_user) { reporter }

        it { is_expected.to be_allowed(:view_group_ci_cd_analytics) }
      end

      context 'when the user has less than reporter permissions' do
        let(:current_user) { guest }

        it { is_expected.not_to be_allowed(:view_group_ci_cd_analytics) }
      end

      context 'when the user has auditor permissions' do
        let(:current_user) { auditor }

        it { is_expected.to be_allowed(:view_group_ci_cd_analytics) }
      end
    end

    context 'when group CI/CD analytics is not available' do
      let(:current_user) { reporter }

      before do
        stub_licensed_features(group_ci_cd_analytics: false)
      end

      it { is_expected.not_to be_allowed(:view_group_ci_cd_analytics) }
    end
  end

  context 'when group repository analytics is available' do
    before do
      stub_licensed_features(group_repository_analytics: true)
    end

    context 'for guests' do
      let(:current_user) { guest }

      it { is_expected.not_to be_allowed(:read_group_repository_analytics) }
    end

    context 'for reporter+' do
      let(:current_user) { reporter }

      it { is_expected.to be_allowed(:read_group_repository_analytics) }
    end

    context 'for auditor' do
      let(:current_user) { auditor }

      it { is_expected.to be_allowed(:read_group_repository_analytics) }
    end
  end

  context 'when group repository analytics is not available' do
    let(:current_user) { maintainer }

    before do
      stub_licensed_features(group_repository_analytics: false)
    end

    it { is_expected.not_to be_allowed(:read_group_repository_analytics) }
  end

  context 'when group cycle analytics is available' do
    before do
      stub_licensed_features(cycle_analytics_for_groups: true)
    end

    context 'for guests' do
      let(:current_user) { guest }

      it { is_expected.not_to be_allowed(:read_group_cycle_analytics) }
    end

    context 'for reporter+' do
      let(:current_user) { reporter }

      it { is_expected.to be_allowed(:read_group_cycle_analytics) }
    end

    context 'for auditor' do
      let(:current_user) { auditor }

      it { is_expected.to be_allowed(:read_group_cycle_analytics) }
    end
  end

  context 'when group cycle analytics is not available' do
    let(:current_user) { maintainer }

    before do
      stub_licensed_features(cycle_analytics_for_groups: false)
    end

    it { is_expected.not_to be_allowed(:read_group_cycle_analytics) }
  end

  context 'when group coverage reports is available' do
    before do
      stub_licensed_features(group_coverage_reports: true)
    end

    context 'for guests' do
      let(:current_user) { guest }

      it { is_expected.not_to be_allowed(:read_group_coverage_reports) }
    end

    context 'for reporter+' do
      let(:current_user) { reporter }

      it { is_expected.to be_allowed(:read_group_coverage_reports) }
    end
  end

  context 'when group coverage reports is not available' do
    let(:current_user) { maintainer }

    before do
      stub_licensed_features(group_coverage_reports: false)
    end

    it { is_expected.not_to be_allowed(:read_group_coverage_reports) }
  end

  describe 'per group SAML' do
    def stub_group_saml_config(enabled)
      allow(::Gitlab::Auth::GroupSaml::Config).to receive_messages(enabled?: enabled)
    end

    context 'when group_saml is unavailable' do
      let(:current_user) { owner }

      context 'when group saml config is disabled' do
        before do
          stub_group_saml_config(false)
        end

        it { is_expected.to be_disallowed(:admin_group_saml) }
      end

      context 'when the group is a subgroup' do
        let_it_be(:subgroup) { create(:group, :private, parent: group) }

        before do
          stub_group_saml_config(true)
        end

        subject { described_class.new(current_user, subgroup) }

        it { is_expected.to be_disallowed(:admin_group_saml) }
      end

      context 'when the feature is not licensed' do
        before do
          stub_group_saml_config(true)
          stub_licensed_features(group_saml: false)
        end

        it { is_expected.to be_disallowed(:admin_group_saml) }
      end
    end

    context 'when group_saml is available' do
      before do
        stub_licensed_features(group_saml: true)
      end

      context 'when group_saml_group_sync is not licensed' do
        context 'with an enabled SAML provider' do
          let_it_be(:saml_provider) { create(:saml_provider, group: group, enabled: true) }

          context 'owner' do
            let(:current_user) { owner }

            it { is_expected.to be_disallowed(:admin_saml_group_links) }
          end

          context 'admin' do
            let(:current_user) { admin }

            it 'is disallowed even with admin mode', :enable_admin_mode do
              is_expected.to be_disallowed(:admin_saml_group_links)
            end
          end
        end
      end

      context 'when group_saml_group_sync is licensed', :saas do
        before do
          stub_group_saml_config(true)
          stub_application_setting(check_namespace_plan: true)
        end

        before_all do
          create(:license, plan: License::ULTIMATE_PLAN)
          create(:gitlab_subscription, :premium, namespace: group)
        end

        context 'without an enabled SAML provider' do
          context 'maintainer' do
            let(:current_user) { maintainer }

            it { is_expected.to be_disallowed(:admin_group_saml) }
            it { is_expected.to be_disallowed(:admin_saml_group_links) }
          end

          context 'owner' do
            let(:current_user) { owner }

            it { is_expected.to be_allowed(:admin_group_saml) }
            it { is_expected.to be_disallowed(:admin_saml_group_links) }
          end

          context 'admin' do
            let(:current_user) { admin }

            context 'when admin mode is enabled', :enable_admin_mode do
              it { is_expected.to be_allowed(:admin_group_saml) }
              it { is_expected.to be_disallowed(:admin_saml_group_links) }
            end

            context 'when admin mode is disabled' do
              it { is_expected.to be_disallowed(:admin_group_saml) }
              it { is_expected.to be_disallowed(:admin_saml_group_links) }
            end
          end
        end

        context 'with an enabled SAML provider' do
          let_it_be(:saml_provider) { create(:saml_provider, group: group, enabled: true) }

          context 'maintainer' do
            let(:current_user) { maintainer }

            it { is_expected.to be_disallowed(:admin_saml_group_links) }
          end

          context 'owner' do
            let(:current_user) { owner }

            it { is_expected.to be_allowed(:admin_saml_group_links) }
          end

          context 'admin' do
            let(:current_user) { admin }

            context 'when admin mode is enabled', :enable_admin_mode do
              it { is_expected.to be_allowed(:admin_saml_group_links) }
            end

            context 'when admin mode is disabled' do
              it { is_expected.to be_disallowed(:admin_saml_group_links) }
            end
          end

          context 'when the group is a subgroup' do
            let_it_be(:subgroup) { create(:group, :private, parent: group) }

            let(:current_user) { owner }

            subject { described_class.new(current_user, subgroup) }

            it { is_expected.to be_allowed(:admin_saml_group_links) }
          end
        end
      end

      context 'with SSO enforcement enabled' do
        let(:current_user) { guest }

        let_it_be(:saml_provider) { create(:saml_provider, group: group, enforced_sso: true) }

        context 'when the session has been set globally' do
          around do |example|
            Gitlab::Session.with_session({}) do
              example.run
            end
          end

          it 'prevents access without a SAML session' do
            is_expected.not_to be_allowed(:read_group)
          end

          it 'allows access with a SAML session' do
            Gitlab::Auth::GroupSaml::SsoEnforcer.new(saml_provider).update_session

            is_expected.to be_allowed(:read_group)
          end
        end

        context 'when there is no global session or sso state' do
          it "allows access because we haven't yet restricted all use cases" do
            is_expected.to be_allowed(:read_group)
          end

          context 'when the current user is a deploy token' do
            let(:current_user) { create(:deploy_token, :group, groups: [group], read_package_registry: true) }

            it 'allows access without a SAML session' do
              is_expected.to allow_action(:read_group)
            end
          end
        end
      end

      context 'without SSO enforcement enabled' do
        let(:current_user) { guest }

        let_it_be(:saml_provider) { create(:saml_provider, group: group, enforced_sso: false) }

        context 'when the session has been set globally' do
          around do |example|
            Gitlab::Session.with_session({}) do
              example.run
            end
          end

          it 'allows access when the user has no Group SAML identity' do
            is_expected.to be_allowed(:read_group)
          end
        end

        context 'when there is no global session or sso state' do
          context 'when the current user is a deploy token' do
            let(:current_user) { create(:deploy_token, :group, groups: [group], read_package_registry: true) }

            it 'allows access without a SAML session' do
              is_expected.to allow_action(:read_group)
            end
          end
        end
      end
    end

    context 'reading a group' do
      context 'when SAML SSO is enabled for resource' do
        using RSpec::Parameterized::TableSyntax

        let(:saml_provider) { create(:saml_provider, enabled: true, enforced_sso: false) }
        let(:identity) { create(:group_saml_identity, saml_provider: saml_provider) }
        let(:root_group) { saml_provider.group }
        let(:subgroup) { create(:group, parent: root_group) }
        let(:member_with_identity) { identity.user }
        let(:member_without_identity) { create(:user) }
        let(:non_member) { create(:user) }
        let(:not_signed_in_user) { nil }

        before do
          stub_licensed_features(group_saml: true)
          root_group.add_developer(member_with_identity)
          root_group.add_developer(member_without_identity)
        end

        subject { described_class.new(current_user, resource) }

        shared_examples 'does not allow read group' do
          it 'does not allow read group' do
            is_expected.not_to allow_action(:read_group)
          end
        end

        shared_examples 'allows to read group' do
          it 'allows read group' do
            is_expected.to allow_action(:read_group)
          end
        end

        shared_examples 'does not allow to read group due to its visibility level' do
          it 'does not allow to read group due to its visibility level', :aggregate_failures do
            expect(resource.root_ancestor.saml_provider.enforced_sso?).to eq(false)

            is_expected.not_to allow_action(:read_group)
          end
        end

        # See https://docs.gitlab.com/ee/user/group/saml_sso/#sso-enforcement
        where(:resource, :resource_visibility_level, :enforced_sso?, :user, :user_is_resource_owner?, :user_with_saml_session?, :user_is_admin?, :enable_admin_mode?, :user_is_auditor?, :shared_examples) do
          # Project/Group visibility: Private; Enforce SSO setting: Off

          ref(:root_group) | 'private' | false | ref(:member_with_identity)    | false | false | nil  | nil   | nil  | 'does not allow read group'
          ref(:root_group) | 'private' | false | ref(:member_with_identity)    | true  | false | nil  | nil   | nil  | 'allows to read group'
          ref(:root_group) | 'private' | false | ref(:member_with_identity)    | false | true  | nil  | nil   | nil  | 'allows to read group'
          ref(:root_group) | 'private' | false | ref(:member_with_identity)    | false | false | true | false | nil  | 'does not allow read group'
          ref(:root_group) | 'private' | false | ref(:member_with_identity)    | false | false | true | true  | nil  | 'allows to read group'
          ref(:root_group) | 'private' | false | ref(:member_with_identity)    | false | false | nil  | nil   | true | 'allows to read group'
          ref(:subgroup)   | 'private' | false | ref(:member_with_identity)    | false | false | nil  | nil   | nil  | 'does not allow read group'
          ref(:subgroup)   | 'private' | false | ref(:member_with_identity)    | true  | false | nil  | nil   | nil  | 'does not allow read group'
          ref(:subgroup)   | 'private' | false | ref(:member_with_identity)    | false | true  | nil  | nil   | nil  | 'allows to read group'
          ref(:subgroup)   | 'private' | false | ref(:member_with_identity)    | false | false | true | false | nil  | 'does not allow read group'
          ref(:subgroup)   | 'private' | false | ref(:member_with_identity)    | false | false | true | true  | nil  | 'allows to read group'
          ref(:subgroup)   | 'private' | false | ref(:member_with_identity)    | false | false | nil  | nil   | true | 'allows to read group'

          ref(:root_group) | 'private' | false | ref(:member_without_identity) | false | nil   | nil  | nil   | nil  | 'allows to read group'
          ref(:subgroup)   | 'private' | false | ref(:member_without_identity) | false | nil   | nil  | nil   | nil  | 'allows to read group'

          ref(:root_group) | 'private' | false | ref(:non_member)              | nil   | nil   | nil  | nil   | nil  | 'does not allow to read group due to its visibility level'
          ref(:root_group) | 'private' | false | ref(:non_member)              | nil   | nil   | true | false | nil  | 'does not allow to read group due to its visibility level'
          ref(:root_group) | 'private' | false | ref(:non_member)              | nil   | nil   | true | true  | nil  | 'allows to read group'
          ref(:root_group) | 'private' | false | ref(:non_member)              | nil   | nil   | nil  | nil   | true | 'allows to read group'
          ref(:root_group) | 'private' | false | ref(:not_signed_in_user)      | nil   | nil   | nil  | nil   | nil  | 'does not allow to read group due to its visibility level'
          ref(:subgroup)   | 'private' | false | ref(:non_member)              | nil   | nil   | nil  | nil   | nil  | 'does not allow to read group due to its visibility level'
          ref(:subgroup)   | 'private' | false | ref(:non_member)              | nil   | nil   | true | false | nil  | 'does not allow to read group due to its visibility level'
          ref(:subgroup)   | 'private' | false | ref(:non_member)              | nil   | nil   | true | true  | nil  | 'allows to read group'
          ref(:subgroup)   | 'private' | false | ref(:non_member)              | nil   | nil   | nil  | nil   | true | 'allows to read group'
          ref(:subgroup)   | 'private' | false | ref(:not_signed_in_user)      | nil   | nil   | nil  | nil   | nil  | 'does not allow to read group due to its visibility level'

          # Project/Group visibility: Private; Enforce SSO setting: On

          ref(:root_group) | 'private' | true  | ref(:member_with_identity)    | false | false | nil  | nil   | nil  | 'does not allow read group'
          ref(:root_group) | 'private' | true  | ref(:member_with_identity)    | true  | false | nil  | nil   | nil  | 'allows to read group'
          ref(:root_group) | 'private' | true  | ref(:member_with_identity)    | false | true  | nil  | nil   | nil  | 'allows to read group'
          ref(:root_group) | 'private' | true  | ref(:member_with_identity)    | false | false | true | false | nil  | 'does not allow read group'
          ref(:root_group) | 'private' | true  | ref(:member_with_identity)    | false | false | true | true  | nil  | 'allows to read group'
          ref(:root_group) | 'private' | true  | ref(:member_with_identity)    | false | false | nil  | nil   | true | 'allows to read group'
          ref(:subgroup)   | 'private' | true  | ref(:member_with_identity)    | false | false | nil  | nil   | nil  | 'does not allow read group'
          ref(:subgroup)   | 'private' | true  | ref(:member_with_identity)    | true  | false | nil  | nil   | nil  | 'does not allow read group'
          ref(:subgroup)   | 'private' | true  | ref(:member_with_identity)    | false | true  | nil  | nil   | nil  | 'allows to read group'
          ref(:subgroup)   | 'private' | true  | ref(:member_with_identity)    | false | false | true | false | nil  | 'does not allow read group'
          ref(:subgroup)   | 'private' | true  | ref(:member_with_identity)    | false | false | true | true  | nil  | 'allows to read group'
          ref(:subgroup)   | 'private' | true  | ref(:member_with_identity)    | false | false | nil  | nil   | true | 'allows to read group'

          ref(:root_group) | 'private' | true  | ref(:member_without_identity) | false | nil   | nil  | nil   | nil  | 'does not allow read group'
          ref(:root_group) | 'private' | true  | ref(:member_without_identity) | true  | nil   | nil  | nil   | nil  | 'allows to read group'
          ref(:root_group) | 'private' | true  | ref(:member_without_identity) | false | nil   | true | false | nil  | 'does not allow read group'
          ref(:root_group) | 'private' | true  | ref(:member_without_identity) | false | nil   | true | true  | nil  | 'allows to read group'
          ref(:root_group) | 'private' | true  | ref(:member_without_identity) | false | nil   | nil  | nil   | true | 'allows to read group'
          ref(:subgroup)   | 'private' | true  | ref(:member_without_identity) | false | nil   | nil  | nil   | nil  | 'does not allow read group'
          ref(:subgroup)   | 'private' | true  | ref(:member_without_identity) | true  | nil   | nil  | nil   | nil  | 'does not allow read group'
          ref(:subgroup)   | 'private' | true  | ref(:member_without_identity) | false | nil   | true | false | nil  | 'does not allow read group'
          ref(:subgroup)   | 'private' | true  | ref(:member_without_identity) | false | nil   | true | true  | nil  | 'allows to read group'
          ref(:subgroup)   | 'private' | true  | ref(:member_without_identity) | false | nil   | nil  | nil   | true | 'allows to read group'

          ref(:root_group) | 'private' | true  | ref(:non_member)              | nil   | nil   | nil  | nil   | nil  | 'does not allow read group'
          ref(:root_group) | 'private' | true  | ref(:non_member)              | nil   | nil   | true | false | nil  | 'does not allow read group'
          ref(:root_group) | 'private' | true  | ref(:non_member)              | nil   | nil   | true | true  | nil  | 'allows to read group'
          ref(:root_group) | 'private' | true  | ref(:non_member)              | nil   | nil   | nil  | nil   | true | 'allows to read group'
          ref(:root_group) | 'private' | true  | ref(:not_signed_in_user)      | nil   | nil   | nil  | nil   | nil  | 'does not allow read group'
          ref(:subgroup)   | 'private' | true  | ref(:non_member)              | nil   | nil   | nil  | nil   | nil  | 'does not allow read group'
          ref(:subgroup)   | 'private' | true  | ref(:non_member)              | nil   | nil   | true | false | nil  | 'does not allow read group'
          ref(:subgroup)   | 'private' | true  | ref(:non_member)              | nil   | nil   | true | true  | nil  | 'allows to read group'
          ref(:subgroup)   | 'private' | true  | ref(:non_member)              | nil   | nil   | nil  | nil   | true | 'allows to read group'
          ref(:subgroup)   | 'private' | true  | ref(:not_signed_in_user)      | nil   | nil   | nil  | nil   | nil  | 'does not allow read group'

          # Project/Group visibility: Public; Enforce SSO setting: Off

          ref(:root_group) | 'public'  | false | ref(:member_with_identity)    | false | false | nil  | nil   | nil  | 'does not allow read group'
          ref(:root_group) | 'public'  | false | ref(:member_with_identity)    | true  | false | nil  | nil   | nil  | 'allows to read group'
          ref(:root_group) | 'public'  | false | ref(:member_with_identity)    | false | true  | nil  | nil   | nil  | 'allows to read group'
          ref(:root_group) | 'public'  | false | ref(:member_with_identity)    | false | false | true | false | nil  | 'does not allow read group'
          ref(:root_group) | 'public'  | false | ref(:member_with_identity)    | false | false | true | true  | nil  | 'allows to read group'
          ref(:root_group) | 'public'  | false | ref(:member_with_identity)    | false | false | nil  | nil   | true | 'allows to read group'
          ref(:subgroup)   | 'public'  | false | ref(:member_with_identity)    | false | false | nil  | nil   | nil  | 'does not allow read group'
          ref(:subgroup)   | 'public'  | false | ref(:member_with_identity)    | true  | false | nil  | nil   | nil  | 'does not allow read group'
          ref(:subgroup)   | 'public'  | false | ref(:member_with_identity)    | false | true  | nil  | nil   | nil  | 'allows to read group'
          ref(:subgroup)   | 'public'  | false | ref(:member_with_identity)    | false | false | true | false | nil  | 'does not allow read group'
          ref(:subgroup)   | 'public'  | false | ref(:member_with_identity)    | false | false | true | true  | nil  | 'allows to read group'
          ref(:subgroup)   | 'public'  | false | ref(:member_with_identity)    | false | false | nil  | nil   | true | 'allows to read group'

          ref(:root_group) | 'public'  | false | ref(:member_without_identity) | false | nil   | nil  | nil   | nil  | 'allows to read group'
          ref(:subgroup)   | 'public'  | false | ref(:member_without_identity) | false | nil   | nil  | nil   | nil  | 'allows to read group'

          ref(:root_group) | 'public'  | false | ref(:non_member)              | nil   | nil   | nil  | nil   | nil  | 'allows to read group'
          ref(:root_group) | 'public'  | false | ref(:not_signed_in_user)      | nil   | nil   | nil  | nil   | nil  | 'allows to read group'
          ref(:subgroup)   | 'public'  | false | ref(:non_member)              | nil   | nil   | nil  | nil   | nil  | 'allows to read group'
          ref(:subgroup)   | 'public'  | false | ref(:not_signed_in_user)      | nil   | nil   | nil  | nil   | nil  | 'allows to read group'

          # Project/Group visibility: Public; Enforce SSO setting: On

          ref(:root_group) | 'public'  | true  | ref(:member_with_identity)    | false | false | nil  | nil   | nil  | 'does not allow read group'
          ref(:root_group) | 'public'  | true  | ref(:member_with_identity)    | true  | false | nil  | nil   | nil  | 'allows to read group'
          ref(:root_group) | 'public'  | true  | ref(:member_with_identity)    | false | true  | nil  | nil   | nil  | 'allows to read group'
          ref(:root_group) | 'public'  | true  | ref(:member_with_identity)    | false | false | true | false | nil  | 'does not allow read group'
          ref(:root_group) | 'public'  | true  | ref(:member_with_identity)    | false | false | true | true  | nil  | 'allows to read group'
          ref(:root_group) | 'public'  | true  | ref(:member_with_identity)    | false | false | nil  | nil   | true | 'allows to read group'
          ref(:subgroup)   | 'public'  | true  | ref(:member_with_identity)    | false | false | nil  | nil   | nil  | 'does not allow read group'
          ref(:subgroup)   | 'public'  | true  | ref(:member_with_identity)    | true  | false | nil  | nil   | nil  | 'does not allow read group'
          ref(:subgroup)   | 'public'  | true  | ref(:member_with_identity)    | false | true  | nil  | nil   | nil  | 'allows to read group'
          ref(:subgroup)   | 'public'  | true  | ref(:member_with_identity)    | false | false | true | false | nil  | 'does not allow read group'
          ref(:subgroup)   | 'public'  | true  | ref(:member_with_identity)    | false | false | true | true  | nil  | 'allows to read group'
          ref(:subgroup)   | 'public'  | true  | ref(:member_with_identity)    | false | false | nil  | nil   | true | 'allows to read group'

          ref(:root_group) | 'public'  | true  | ref(:member_without_identity) | false | nil   | nil  | nil   | nil  | 'does not allow read group'
          ref(:root_group) | 'public'  | true  | ref(:member_without_identity) | true  | nil   | nil  | nil   | nil  | 'allows to read group'
          ref(:root_group) | 'public'  | true  | ref(:member_without_identity) | false | nil   | true | false | nil  | 'does not allow read group'
          ref(:root_group) | 'public'  | true  | ref(:member_without_identity) | false | nil   | true | true  | nil  | 'allows to read group'
          ref(:root_group) | 'public'  | true  | ref(:member_without_identity) | false | nil   | nil  | nil   | true | 'allows to read group'
          ref(:subgroup)   | 'public'  | true  | ref(:member_without_identity) | false | nil   | nil  | nil   | nil  | 'does not allow read group'
          ref(:subgroup)   | 'public'  | true  | ref(:member_without_identity) | true  | nil   | nil  | nil   | nil  | 'does not allow read group'
          ref(:subgroup)   | 'public'  | true  | ref(:member_without_identity) | false | nil   | true | false | nil  | 'does not allow read group'
          ref(:subgroup)   | 'public'  | true  | ref(:member_without_identity) | false | nil   | true | true  | nil  | 'allows to read group'
          ref(:subgroup)   | 'public'  | true  | ref(:member_without_identity) | false | nil   | nil  | nil   | true | 'allows to read group'

          ref(:root_group) | 'public'  | true  | ref(:non_member)              | nil   | nil   | nil  | nil   | nil  | 'allows to read group'
          ref(:root_group) | 'public'  | true  | ref(:not_signed_in_user)      | nil   | nil   | nil  | nil   | nil  | 'allows to read group'
          ref(:subgroup)   | 'public'  | true  | ref(:non_member)              | nil   | nil   | nil  | nil   | nil  | 'allows to read group'
          ref(:subgroup)   | 'public'  | true  | ref(:not_signed_in_user)      | nil   | nil   | nil  | nil   | nil  | 'allows to read group'
        end

        with_them do
          context "when 'Enforce SSO-only authentication for web activity for this group' option is #{params[:enforced_sso?] ? 'enabled' : 'not enabled'}" do
            around do |example|
              Gitlab::Session.with_session({}) do
                example.run
              end
            end

            before do
              saml_provider.update!(enforced_sso: enforced_sso?)
            end

            context "when resource is #{params[:resource_visibility_level]}" do
              before do
                resource.update!(visibility_level: Gitlab::VisibilityLevel.string_options[resource_visibility_level])
              end

              context 'for user', enable_admin_mode: params[:enable_admin_mode?] do
                before do
                  if user_is_resource_owner?
                    resource.root_ancestor.member(user).update_column(:access_level, Gitlab::Access::OWNER)
                  end

                  Gitlab::Auth::GroupSaml::SsoEnforcer.new(saml_provider).update_session if user_with_saml_session?

                  user.update!(admin: true) if user_is_admin?
                  user.update!(auditor: true) if user_is_auditor?
                end

                let(:current_user) { user }

                include_examples params[:shared_examples]
              end
            end
          end
        end
      end
    end
  end

  describe 'admin_saml_group_links for global SAML' do
    let(:current_user) { owner }

    it { is_expected.to be_disallowed(:admin_saml_group_links) }

    context 'when global SAML is enabled' do
      before do
        allow(Gitlab::Auth::Saml::Config).to receive_messages({ options: { name: 'saml', args: {} } })
        allow(Gitlab::Auth::OAuth::Provider).to receive(:providers).and_return([:saml])
      end

      it { is_expected.to be_disallowed(:admin_saml_group_links) }

      context 'when the groups attribute is configured' do
        before do
          allow(Gitlab::Auth::Saml::Config).to receive(:groups).and_return(['Groups'])
        end

        it { is_expected.to be_disallowed(:admin_saml_group_links) }

        context 'when saml_group_sync feature is licensed' do
          before do
            stub_licensed_features(saml_group_sync: true)
          end

          it { is_expected.to be_allowed(:admin_saml_group_links) }

          context 'when the current user is not an admin or owner' do
            let(:current_user) { maintainer }

            it { is_expected.to be_disallowed(:admin_saml_group_links) }
          end
        end
      end
    end
  end

  context 'with ip restriction' do
    let(:current_user) { maintainer }

    before do
      allow(Gitlab::IpAddressState).to receive(:current).and_return('192.168.0.2')
      stub_licensed_features(group_ip_restriction: true)
      stub_config(dependency_proxy: { enabled: true })
    end

    context 'without restriction' do
      it { is_expected.to be_allowed(:read_group) }
      it { is_expected.to be_allowed(:read_milestone) }
      it { is_expected.to be_allowed(:read_package) }
      it { is_expected.to be_allowed(:create_package) }
      it { is_expected.to be_allowed(:destroy_package) }
      it { is_expected.to be_allowed(:admin_package) }
      it { is_expected.to be_allowed(:read_dependency_proxy) }
      it { is_expected.to be_allowed(:admin_dependency_proxy) }
    end

    context 'with restriction' do
      before do
        create(:ip_restriction, group: group, range: range)
      end

      context 'address is within the range' do
        let(:range) { '192.168.0.0/24' }

        it { is_expected.to be_allowed(:read_group) }
        it { is_expected.to be_allowed(:read_milestone) }
        it { is_expected.to be_allowed(:read_package) }
        it { is_expected.to be_allowed(:create_package) }
        it { is_expected.to be_allowed(:destroy_package) }
        it { is_expected.to be_allowed(:admin_package) }
        it { is_expected.to be_allowed(:read_dependency_proxy) }
        it { is_expected.to be_allowed(:admin_dependency_proxy) }
      end

      context 'address is outside the range' do
        let(:range) { '10.0.0.0/8' }

        context 'as maintainer' do
          it { is_expected.to be_disallowed(:read_group) }
          it { is_expected.to be_disallowed(:read_milestone) }
          it { is_expected.to be_disallowed(:read_package) }
          it { is_expected.to be_disallowed(:create_package) }
          it { is_expected.to be_disallowed(:destroy_package) }
          it { is_expected.to be_disallowed(:admin_package) }
          it { is_expected.to be_disallowed(:read_dependency_proxy) }
          it { is_expected.to be_disallowed(:admin_dependency_proxy) }
        end

        context 'as owner' do
          let(:current_user) { owner }

          it { is_expected.to be_allowed(:read_group) }
          it { is_expected.to be_allowed(:read_milestone) }
          it { is_expected.to be_allowed(:read_package) }
          it { is_expected.to be_allowed(:create_package) }
          it { is_expected.to be_allowed(:destroy_package) }
          it { is_expected.to be_allowed(:admin_package) }
          it { is_expected.to be_allowed(:read_dependency_proxy) }
          it { is_expected.to be_allowed(:admin_dependency_proxy) }
        end

        context 'as auditor' do
          let(:current_user) { create(:user, :auditor) }

          it { is_expected.to be_allowed(:read_group) }
          it { is_expected.to be_allowed(:read_milestone) }
          it { is_expected.to be_allowed(:read_group_audit_events) }
          it { is_expected.to be_allowed(:read_dependency_proxy) }
          it { is_expected.to be_disallowed(:admin_dependency_proxy) }
        end
      end
    end
  end

  context 'when LDAP sync is not enabled' do
    context 'owner' do
      let(:current_user) { owner }

      it { is_expected.to be_disallowed(:override_group_member) }
      it { is_expected.to be_allowed(:admin_ldap_group_links) }
      it { is_expected.to be_allowed(:admin_ldap_group_settings) }

      context 'does not allow group owners to manage ldap' do
        before do
          stub_application_setting(allow_group_owners_to_manage_ldap: false)
        end

        it { is_expected.to be_disallowed(:admin_ldap_group_links) }
        it { is_expected.to be_disallowed(:admin_ldap_group_settings) }
      end
    end

    context 'admin' do
      let(:current_user) { admin }

      context 'when admin mode is enabled', :enable_admin_mode do
        it { is_expected.to be_disallowed(:override_group_member) }
        it { is_expected.to be_allowed(:admin_ldap_group_links) }
        it { is_expected.to be_allowed(:admin_ldap_group_settings) }
      end

      context 'when admin mode is disabled' do
        it { is_expected.to be_disallowed(:override_group_member) }
        it { is_expected.to be_disallowed(:admin_ldap_group_links) }
        it { is_expected.to be_disallowed(:admin_ldap_group_settings) }
      end
    end
  end

  context 'when memberships locked to SAML' do
    context 'when group is a root group' do
      before do
        stub_application_setting(lock_memberships_to_saml: true)
      end

      context 'when SAML group link sync is enabled' do
        before do
          allow(group).to receive(:saml_group_links_enabled?).and_return(true)
        end

        context 'admin' do
          let(:current_user) { admin }

          context 'when admin mode is enabled', :enable_admin_mode do
            it { is_expected.to be_allowed(:admin_group_member) }
          end

          context 'when admin mode is disabled' do
            it { is_expected.not_to be_allowed(:admin_group_member) }
          end
        end

        context 'owner' do
          let(:current_user) { owner }

          it { is_expected.not_to be_allowed(:admin_group_member) }
        end

        context 'maintainer' do
          let(:current_user) { maintainer }

          it { is_expected.not_to be_allowed(:admin_group_member) }
        end
      end

      context 'when no SAML sync is enabled' do
        before do
          allow(group).to receive(:saml_group_links_enabled?).and_return(false)
        end

        context 'admin' do
          let(:current_user) { admin }

          it { is_expected.not_to be_allowed(:admin_group_member) }
        end

        context 'owner' do
          let(:current_user) { owner }

          it { is_expected.to be_allowed(:admin_group_member) }
        end
      end
    end

    context 'when group is not a root group' do
      let(:parent_group) { create(:group) }
      let(:group) { create(:group, :private, parent: parent_group) }

      before do
        group.add_owner(owner)
        parent_group.add_owner(owner)
        stub_application_setting(lock_memberships_to_saml: true)
      end

      context 'when SAML group link sync is enabled' do
        before do
          allow(group.root_ancestor).to receive(:saml_group_links_enabled?).and_return(true)
        end

        context 'admin' do
          let(:current_user) { admin }

          context 'when admin mode is enabled', :enable_admin_mode do
            it { is_expected.to be_allowed(:admin_group_member) }
          end

          context 'when admin mode is disabled' do
            it { is_expected.not_to be_allowed(:admin_group_member) }
          end
        end

        context 'owner' do
          let(:current_user) { owner }

          it { is_expected.not_to be_allowed(:admin_group_member) }
        end

        context 'maintainer' do
          let(:current_user) { maintainer }

          it { is_expected.not_to be_allowed(:admin_group_member) }
        end

        context 'when child group has different owner than parent group' do
          let(:sub_group_owner) { create(:user) }
          let(:current_user) { sub_group_owner }

          before do
            group.add_owner(sub_group_owner)
          end

          it { is_expected.not_to be_allowed(:admin_group_member) }
        end
      end

      context 'when no SAML group link sync is enabled' do
        before do
          allow(group).to receive(:saml_group_links_enabled?).and_return(false)
        end

        context 'admin' do
          let(:current_user) { admin }

          it { is_expected.to be_disallowed(:admin_group_member) }
        end

        context 'owner' do
          let(:current_user) { owner }

          it { is_expected.to be_allowed(:admin_group_member) }
        end

        context 'maintainer' do
          let(:current_user) { maintainer }

          it { is_expected.to be_disallowed(:admin_group_member) }
        end
      end
    end
  end

  context 'when LDAP sync is enabled' do
    before do
      allow(group).to receive(:ldap_synced?).and_return(true)
    end

    context 'with no user' do
      let(:current_user) { nil }

      it { is_expected.to be_disallowed(:override_group_member) }
      it { is_expected.to be_disallowed(:admin_ldap_group_links) }
      it { is_expected.to be_disallowed(:admin_ldap_group_settings) }
    end

    context 'guests' do
      let(:current_user) { guest }

      it { is_expected.to be_disallowed(:override_group_member) }
      it { is_expected.to be_disallowed(:admin_ldap_group_links) }
      it { is_expected.to be_disallowed(:admin_ldap_group_settings) }
    end

    context 'reporter' do
      let(:current_user) { reporter }

      it { is_expected.to be_disallowed(:override_group_member) }
      it { is_expected.to be_disallowed(:admin_ldap_group_links) }
      it { is_expected.to be_disallowed(:admin_ldap_group_settings) }
    end

    context 'developer' do
      let(:current_user) { developer }

      it { is_expected.to be_disallowed(:override_group_member) }
      it { is_expected.to be_disallowed(:admin_ldap_group_links) }
      it { is_expected.to be_disallowed(:admin_ldap_group_settings) }
    end

    context 'maintainer' do
      let(:current_user) { maintainer }

      it { is_expected.to be_disallowed(:override_group_member) }
      it { is_expected.to be_disallowed(:admin_ldap_group_links) }
      it { is_expected.to be_disallowed(:admin_ldap_group_settings) }
    end

    context 'owner' do
      let(:current_user) { owner }

      context 'allow group owners to manage ldap' do
        it { is_expected.to be_allowed(:override_group_member) }
      end

      context 'does not allow group owners to manage ldap' do
        before do
          stub_application_setting(allow_group_owners_to_manage_ldap: false)
        end

        it { is_expected.to be_disallowed(:override_group_member) }
        it { is_expected.to be_disallowed(:admin_ldap_group_links) }
        it { is_expected.to be_disallowed(:admin_ldap_group_settings) }
      end
    end

    context 'admin' do
      let(:current_user) { admin }

      context 'when admin mode is enabled', :enable_admin_mode do
        it { is_expected.to be_allowed(:override_group_member) }
        it { is_expected.to be_allowed(:admin_ldap_group_links) }
        it { is_expected.to be_allowed(:admin_ldap_group_settings) }
      end

      context 'when admin mode is disabled' do
        it { is_expected.to be_disallowed(:override_group_member) }
        it { is_expected.to be_disallowed(:admin_ldap_group_links) }
        it { is_expected.to be_disallowed(:admin_ldap_group_settings) }
      end
    end

    context 'when memberships locked to LDAP' do
      before do
        stub_application_setting(allow_group_owners_to_manage_ldap: true)
        stub_application_setting(lock_memberships_to_ldap: true)
      end

      context 'admin' do
        let(:current_user) { admin }

        context 'when admin mode enabled', :enable_admin_mode do
          it { is_expected.to be_allowed(:override_group_member) }
          it { is_expected.to be_allowed(:update_group_member) }
        end

        context 'when admin mode disabled' do
          it { is_expected.to be_disallowed(:override_group_member) }
          it { is_expected.to be_disallowed(:update_group_member) }
        end
      end

      context 'owner' do
        let(:current_user) { owner }

        it { is_expected.not_to be_allowed(:admin_group_member) }
        it { is_expected.not_to be_allowed(:override_group_member) }
        it { is_expected.not_to be_allowed(:update_group_member) }
      end

      context 'when LDAP sync is enabled' do
        let(:current_user) { owner }

        before do
          allow(group).to receive(:ldap_synced?).and_return(true)
        end

        context 'Group Owner disable membership lock' do
          before do
            group.update!(unlock_membership_to_ldap: true)
            stub_feature_flags(ldap_settings_unlock_groups_by_owners: true)
          end

          it { is_expected.to be_allowed(:admin_group_member) }
          it { is_expected.to be_allowed(:override_group_member) }
          it { is_expected.to be_allowed(:update_group_member) }

          context 'ldap_settings_unlock_groups_by_owners is disabled' do
            before do
              stub_feature_flags(ldap_settings_unlock_groups_by_owners: false)
            end

            it { is_expected.to be_disallowed(:admin_group_member) }
            it { is_expected.to be_disallowed(:override_group_member) }
            it { is_expected.to be_disallowed(:update_group_member) }
          end
        end

        context 'Group Owner keeps the membership lock' do
          before do
            group.update!(unlock_membership_to_ldap: false)
          end

          it { is_expected.not_to be_allowed(:admin_group_member) }
          it { is_expected.not_to be_allowed(:override_group_member) }
          it { is_expected.not_to be_allowed(:update_group_member) }
        end
      end

      context 'when LDAP sync is disable' do
        let(:current_user) { owner }

        it { is_expected.not_to be_allowed(:admin_group_member) }
        it { is_expected.not_to be_allowed(:override_group_member) }
        it { is_expected.not_to be_allowed(:update_group_member) }
      end
    end
  end

  describe 'read_group_credentials_inventory' do
    context 'with admin' do
      let(:current_user) { admin }

      context 'when admin mode is enabled', :enable_admin_mode do
        it { is_expected.to be_allowed(:read_group_credentials_inventory) }
      end

      context 'when admin mode is disabled' do
        it { is_expected.to be_disallowed(:read_group_credentials_inventory) }
      end
    end

    context 'with owner' do
      let(:current_user) { owner }

      it { is_expected.to be_allowed(:read_group_credentials_inventory) }
    end

    context 'with maintainer' do
      let(:current_user) { maintainer }

      it { is_expected.to be_disallowed(:read_group_credentials_inventory) }
    end

    context 'with developer' do
      let(:current_user) { developer }

      it { is_expected.to be_disallowed(:read_group_credentials_inventory) }

      context 'when security dashboard features is not available' do
        before do
          stub_licensed_features(security_dashboard: false)
        end

        it { is_expected.to be_disallowed(:read_group_credentials_inventory) }
      end
    end

    context 'with reporter' do
      let(:current_user) { reporter }

      it { is_expected.to be_disallowed(:read_group_credentials_inventory) }
    end

    context 'with guest' do
      let(:current_user) { guest }

      it { is_expected.to be_disallowed(:read_group_credentials_inventory) }
    end

    context 'with non member' do
      let(:current_user) { create(:user) }

      it { is_expected.to be_disallowed(:read_group_credentials_inventory) }
    end

    context 'with anonymous' do
      let(:current_user) { nil }

      it { is_expected.to be_disallowed(:read_group_credentials_inventory) }
    end
  end

  describe 'change_prevent_group_forking' do
    context 'when feature is disabled' do
      context 'with owner' do
        let(:current_user) { owner }

        it { is_expected.to be_disallowed(:change_prevent_group_forking) }
      end

      context 'with maintainer' do
        let(:current_user) { maintainer }

        it { is_expected.to be_disallowed(:change_prevent_group_forking) }
      end
    end

    context 'when feature is enabled' do
      before do
        stub_licensed_features(group_forking_protection: true)
      end

      context 'with owner' do
        let(:current_user) { owner }

        it { is_expected.to be_allowed(:change_prevent_group_forking) }

        context 'when group has parent' do
          let(:group) { create(:group, :private, parent: create(:group)) }

          it { is_expected.to be_disallowed(:change_prevent_group_forking) }
        end
      end

      context 'with maintainer' do
        let(:current_user) { maintainer }

        it { is_expected.to be_disallowed(:change_prevent_group_forking) }
      end
    end
  end

  describe 'security orchestration policies' do
    before do
      stub_licensed_features(security_orchestration_policies: true)
    end

    context 'with developer or maintainer role' do
      where(role: %w[maintainer developer])

      with_them do
        let(:current_user) { public_send(role) }

        it { is_expected.to be_allowed(:read_security_orchestration_policies) }
      end
    end

    context 'with owner role' do
      where(role: %w[owner])

      with_them do
        let(:current_user) { public_send(role) }

        it { is_expected.to be_allowed(:read_security_orchestration_policies) }
      end
    end

    context 'with auditor role' do
      where(role: %w[auditor])

      with_them do
        let(:current_user) { public_send(role) }

        it { is_expected.to be_allowed(:read_security_orchestration_policies) }
      end
    end
  end

  describe 'admin_vulnerability' do
    before do
      stub_licensed_features(security_dashboard: true)
    end

    context 'with guest' do
      let(:current_user) { auditor }

      it { is_expected.to be_disallowed(:admin_vulnerability) }
    end

    context 'with reporter' do
      let(:current_user) { reporter }

      it { is_expected.to be_disallowed(:admin_vulnerability) }
    end

    context 'with developer' do
      let(:current_user) { developer }

      it { is_expected.to be_allowed(:admin_vulnerability) }
    end

    context 'with maintainer' do
      let(:current_user) { maintainer }

      it { is_expected.to be_allowed(:admin_vulnerability) }
    end

    context 'with owner' do
      let(:current_user) { owner }

      it { is_expected.to be_allowed(:admin_vulnerability) }
    end

    context 'with auditor' do
      let(:current_user) { auditor }

      context "when auditor is not a group member" do
        it { is_expected.to be_disallowed(:admin_vulnerability) }
      end

      context "when developer doesn't have developer-level access to a group" do
        before do
          group.add_reporter(auditor)
        end

        it { is_expected.to be_disallowed(:admin_vulnerability) }
      end

      context 'when auditor has developer-level access to a group' do
        before do
          group.add_developer(auditor)
        end

        it { is_expected.to be_allowed(:admin_vulnerability) }
      end
    end
  end

  describe 'read_group_security_dashboard & create_vulnerability_export' do
    let(:abilities) do
      %i[read_group_security_dashboard create_vulnerability_export read_security_resource]
    end

    before do
      stub_licensed_features(security_dashboard: true)
    end

    context 'with admin' do
      let(:current_user) { admin }

      context 'when admin mode is enabled', :enable_admin_mode do
        it { is_expected.to be_allowed(*abilities) }
      end

      context 'when admin mode is disabled' do
        it { is_expected.to be_disallowed(*abilities) }
      end
    end

    context 'with owner' do
      let(:current_user) { owner }

      it { is_expected.to be_allowed(*abilities) }
    end

    context 'with maintainer' do
      let(:current_user) { maintainer }

      it { is_expected.to be_allowed(*abilities) }
    end

    context 'with developer' do
      let(:current_user) { developer }

      it { is_expected.to be_allowed(*abilities) }

      context 'when security dashboard features is not available' do
        before do
          stub_licensed_features(security_dashboard: false)
        end

        it { is_expected.to be_disallowed(*abilities) }
      end
    end

    context 'with reporter' do
      let(:current_user) { reporter }

      it { is_expected.to be_disallowed(*abilities) }
    end

    context 'with guest' do
      let(:current_user) { guest }

      it { is_expected.to be_disallowed(*abilities) }
    end

    context 'with non member' do
      let(:current_user) { create(:user) }

      it { is_expected.to be_disallowed(*abilities) }
    end

    context 'with anonymous' do
      let(:current_user) { nil }

      it { is_expected.to be_disallowed(*abilities) }
    end
  end

  describe 'private nested group use the highest access level from the group and inherited permissions' do
    let(:nested_group) { create(:group, :private, parent: group) }

    before do
      nested_group.add_guest(guest)
      nested_group.add_guest(reporter)
      nested_group.add_guest(developer)
      nested_group.add_guest(maintainer)

      group.owners.destroy_all # rubocop: disable Cop/DestroyAll

      group.add_guest(owner)
      nested_group.add_owner(owner)
    end

    subject { described_class.new(current_user, nested_group) }

    context 'auditor' do
      let(:current_user) { create(:user, :auditor) }

      before do
        stub_licensed_features(security_dashboard: true)
      end

      specify do
        expect_allowed(*auditor_permissions)
        expect_disallowed(*(reporter_permissions - auditor_permissions))
        expect_disallowed(*(developer_permissions - auditor_permissions))
        expect_disallowed(*maintainer_permissions)
        expect_disallowed(*(owner_permissions - auditor_permissions))
      end
    end
  end

  context 'commit_committer_check is not enabled by the current license' do
    before do
      stub_licensed_features(commit_committer_check: false)
    end

    let(:current_user) { maintainer }

    it { is_expected.not_to be_allowed(:change_commit_committer_check) }
    it { is_expected.not_to be_allowed(:read_commit_committer_check) }
  end

  context 'commit_committer_check is enabled by the current license' do
    before do
      stub_licensed_features(commit_committer_check: true)
    end

    context 'when the user is an admin', :enable_admin_mode do
      let(:current_user) { admin }

      it { is_expected.to be_allowed(:change_commit_committer_check) }
      it { is_expected.to be_allowed(:read_commit_committer_check) }
    end

    context 'the user is a maintainer' do
      let(:current_user) { maintainer }

      it { is_expected.to be_allowed(:change_commit_committer_check) }
      it { is_expected.to be_allowed(:read_commit_committer_check) }
    end

    context 'the user is a developer' do
      let(:current_user) { developer }

      it { is_expected.not_to be_allowed(:change_commit_committer_check) }
      it { is_expected.to be_allowed(:read_commit_committer_check) }
    end
  end

  context 'reject_unsigned_commits is not enabled by the current license' do
    before do
      stub_licensed_features(reject_unsigned_commits: false)
    end

    let(:current_user) { maintainer }

    it { is_expected.not_to be_allowed(:change_reject_unsigned_commits) }
    it { is_expected.not_to be_allowed(:read_reject_unsigned_commits) }
  end

  context 'reject_unsigned_commits is enabled by the current license' do
    before do
      stub_licensed_features(reject_unsigned_commits: true)
    end

    context 'when the user is an admin', :enable_admin_mode do
      let(:current_user) { admin }

      it { is_expected.to be_allowed(:change_reject_unsigned_commits) }
      it { is_expected.to be_allowed(:read_reject_unsigned_commits) }
    end

    context 'the user is a maintainer' do
      let(:current_user) { maintainer }

      it { is_expected.to be_allowed(:change_reject_unsigned_commits) }
      it { is_expected.to be_allowed(:read_reject_unsigned_commits) }
    end

    context 'the user is a developer' do
      let(:current_user) { developer }

      it { is_expected.not_to be_allowed(:change_reject_unsigned_commits) }
      it { is_expected.to be_allowed(:read_reject_unsigned_commits) }
    end
  end

  shared_examples 'analytics policy' do |action|
    shared_examples 'policy by role' do |role|
      context role do
        let(:current_user) { public_send(role) }

        it 'is allowed' do
          is_expected.to be_allowed(action)
        end
      end
    end

    %w[owner maintainer developer reporter].each do |role|
      include_examples 'policy by role', role
    end

    context 'admin' do
      let(:current_user) { admin }

      it 'is allowed when admin mode is enabled', :enable_admin_mode do
        is_expected.to be_allowed(action)
      end

      it 'is not allowed when admin mode is disabled' do
        is_expected.to be_disallowed(action)
      end
    end

    context 'guest' do
      let(:current_user) { guest }

      it 'is not allowed' do
        is_expected.to be_disallowed(action)
      end
    end
  end

  describe 'view_productivity_analytics' do
    include_examples 'analytics policy', :view_productivity_analytics
  end

  describe 'view_type_of_work_charts' do
    include_examples 'analytics policy', :view_type_of_work_charts
  end

  describe '#read_group_saml_identity' do
    let_it_be(:saml_provider) { create(:saml_provider, group: group, enabled: true) }

    context 'for owner' do
      let(:current_user) { owner }

      it { is_expected.to be_allowed(:read_group_saml_identity) }

      context 'without Group SAML enabled' do
        before do
          saml_provider.update!(enabled: false)
        end

        it { is_expected.to be_disallowed(:read_group_saml_identity) }
      end
    end

    %w[maintainer developer reporter guest].each do |role|
      context "for #{role}" do
        let(:current_user) { public_send(role) }

        it { is_expected.to be_disallowed(:read_group_saml_identity) }
      end
    end
  end

  describe 'update_default_branch_protection' do
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

          context 'when admin mode is enabled', :enable_admin_mode do
            it { is_expected.to be_allowed(:update_default_branch_protection) }
          end

          context 'when admin mode is disabled' do
            it { is_expected.to be_disallowed(:update_default_branch_protection) }
          end
        end

        context 'when the setting `group_owners_can_manage_default_branch_protection` is disabled' do
          before do
            stub_ee_application_setting(group_owners_can_manage_default_branch_protection: false)
          end

          context 'when admin mode is enabled', :enable_admin_mode do
            it { is_expected.to be_allowed(:update_default_branch_protection) }
          end

          context 'when admin mode is disabled' do
            it { is_expected.to be_disallowed(:update_default_branch_protection) }
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

          context 'when admin mode is enabled', :enable_admin_mode do
            it { is_expected.to be_allowed(:update_default_branch_protection) }
          end

          context 'when admin mode is disabled' do
            it { is_expected.to be_disallowed(:update_default_branch_protection) }
          end
        end

        context 'when the setting `group_owners_can_manage_default_branch_protection` is disabled' do
          before do
            stub_ee_application_setting(group_owners_can_manage_default_branch_protection: false)
          end

          context 'when admin mode is enabled', :enable_admin_mode do
            it { is_expected.to be_allowed(:update_default_branch_protection) }
          end

          context 'when admin mode is disabled' do
            it { is_expected.to be_disallowed(:update_default_branch_protection) }
          end
        end
      end
    end

    context 'for an owner' do
      let(:current_user) { owner }

      context 'when the `default_branch_protection_restriction_in_groups` feature is available' do
        before do
          stub_licensed_features(default_branch_protection_restriction_in_groups: true)
        end

        context 'when the setting `group_owners_can_manage_default_branch_protection` is enabled' do
          before do
            stub_ee_application_setting(group_owners_can_manage_default_branch_protection: true)
          end

          it { is_expected.to be_allowed(:update_default_branch_protection) }
        end

        context 'when the setting `group_owners_can_manage_default_branch_protection` is disabled' do
          before do
            stub_ee_application_setting(group_owners_can_manage_default_branch_protection: false)
          end

          it { is_expected.to be_disallowed(:update_default_branch_protection) }
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

          it { is_expected.to be_allowed(:update_default_branch_protection) }
        end

        context 'when the setting `group_owners_can_manage_default_branch_protection` is disabled' do
          before do
            stub_ee_application_setting(group_owners_can_manage_default_branch_protection: false)
          end

          it { is_expected.to be_allowed(:update_default_branch_protection) }
        end
      end
    end
  end

  describe ':admin_ci_minutes' do
    using RSpec::Parameterized::TableSyntax

    let(:policy) { :admin_ci_minutes }

    where(:role, :admin_mode, :allowed) do
      :guest      | nil   | false
      :reporter   | nil   | false
      :developer  | nil   | false
      :maintainer | nil   | false
      :owner      | nil   | true
      :admin      | true  | true
      :admin      | false | false
    end

    with_them do
      let(:current_user) { public_send(role) }

      before do
        enable_admin_mode!(current_user) if admin_mode
      end

      it { is_expected.to(allowed ? be_allowed(policy) : be_disallowed(policy)) }
    end
  end

  describe ':read_group_audit_events' do
    using RSpec::Parameterized::TableSyntax

    let(:policy) { :read_group_audit_events }

    where(:role, :admin_mode, :allowed) do
      :guest      | nil   | false
      :reporter   | nil   | false
      :developer  | nil   | true
      :maintainer | nil   | true
      :owner      | nil   | true
      :admin      | true  | true
      :admin      | false | false
    end

    with_them do
      let(:current_user) { public_send(role) }

      before do
        enable_admin_mode!(current_user) if admin_mode
      end

      it { is_expected.to(allowed ? be_allowed(policy) : be_disallowed(policy)) }
    end
  end

  context 'when group is read only' do
    let(:current_user) { owner }
    let(:policies) do
      %i[create_epic update_epic admin_pipeline admin_group_runners register_group_runners add_cluster
         create_cluster update_cluster admin_cluster create_deploy_token create_subgroup create_package]
    end

    before do
      allow(group).to receive(:read_only?).and_return(read_only)
      stub_licensed_features(epics: true)
    end

    context 'when the group is read only' do
      let(:read_only) { true }

      it { is_expected.to(be_disallowed(*policies)) }
      it { is_expected.to(be_allowed(:read_billable_member)) }
    end

    context 'when the group is not read only' do
      let(:read_only) { false }

      it { is_expected.to(be_allowed(*policies)) }
    end
  end

  context 'under .com', :saas do
    it_behaves_like 'model with wiki policies' do
      let_it_be_with_refind(:container) { create(:group_with_plan, plan: :premium_plan) }
      let_it_be(:user) { owner }

      before_all do
        create(:license, plan: License::PREMIUM_PLAN)
      end

      before do
        enable_namespace_license_check!
      end

      def set_access_level(access_level)
        container.group_feature.update_attribute(:wiki_access_level, access_level)
      end

      context 'when the feature is not licensed on this group' do
        let_it_be(:container) { create(:group_with_plan, plan: :bronze_plan) }

        it 'does not include the wiki permissions' do
          expect_disallowed(*wiki_permissions[:all])
        end
      end
    end
  end

  it_behaves_like 'update namespace limit policy'

  context 'group access tokens', :saas do
    context 'GitLab.com Core resource access tokens', :saas do
      before do
        stub_ee_application_setting(should_check_namespace_plan: true)
      end

      context 'with owner access' do
        let(:current_user) { owner }

        it { is_expected.not_to be_allowed(:create_resource_access_tokens) }
        it { is_expected.not_to be_allowed(:admin_setting_to_allow_resource_access_token_creation) }
        it { is_expected.to be_allowed(:read_resource_access_tokens) }
        it { is_expected.to be_allowed(:destroy_resource_access_tokens) }
      end
    end

    context 'on GitLab.com paid' do
      let_it_be(:group) { create(:group_with_plan, plan: :bronze_plan) }

      context 'with owner' do
        let(:current_user) { owner }

        before do
          group.add_owner(owner)
        end

        it_behaves_like 'GitLab.com Paid plan resource access tokens'

        context 'create resource access tokens' do
          it { is_expected.to be_allowed(:create_resource_access_tokens) }

          context 'when resource access token creation is not allowed' do
            before do
              group.namespace_settings.update_column(:resource_access_token_creation_allowed, false)
            end

            it { is_expected.not_to be_allowed(:create_resource_access_tokens) }
          end

          context 'when parent group has resource access token creation disabled' do
            let(:namespace_settings) { create(:namespace_settings, resource_access_token_creation_allowed: false) }
            let(:parent) { create(:group_with_plan, plan: :bronze_plan, namespace_settings: namespace_settings) }
            let(:group) { create(:group, parent: parent) }

            context 'cannot create resource access tokens' do
              it { is_expected.not_to be_allowed(:create_resource_access_tokens) }
            end

            context 'can render admin settings for resource access token' do
              it { is_expected.to be_allowed(:admin_setting_to_allow_resource_access_token_creation) }
            end
          end
        end

        context 'read resource access tokens' do
          it { is_expected.to be_allowed(:read_resource_access_tokens) }
        end

        context 'destroy resource access tokens' do
          it { is_expected.to be_allowed(:destroy_resource_access_tokens) }
        end

        context 'admin settings `allow resource access token` is allowed' do
          it { is_expected.to be_allowed(:admin_setting_to_allow_resource_access_token_creation) }
        end
      end

      context 'with developer' do
        let(:current_user) { developer }

        before do
          group.add_developer(developer)
        end

        context 'create resource access tokens' do
          it { is_expected.not_to be_allowed(:create_resource_access_tokens) }
        end

        context 'read resource access tokens' do
          it { is_expected.not_to be_allowed(:read_resource_access_tokens) }
        end

        context 'destroy resource access tokens' do
          it { is_expected.not_to be_allowed(:destroy_resource_access_tokens) }
        end
      end
    end
  end

  describe ':read_group_release_stats' do
    shared_examples 'read_group_release_stats permissions' do
      context 'when user is logged out' do
        let(:current_user) { nil }

        it { is_expected.to be_disallowed(:read_group_release_stats) }
      end

      context 'when user is not a member of the group' do
        let(:current_user) { create(:user) }

        it { is_expected.to be_disallowed(:read_group_release_stats) }
      end

      context 'when user is guest' do
        let(:current_user) { guest }

        it { is_expected.to be_allowed(:read_group_release_stats) }
      end
    end

    context 'when group is private' do
      it_behaves_like 'read_group_release_stats permissions'
    end

    context 'when group is public' do
      let(:group) { create(:group, :public) }

      before do
        group.add_guest(guest)
      end

      it_behaves_like 'read_group_release_stats permissions'
    end

    describe ':admin_merge_request_approval_settings' do
      using RSpec::Parameterized::TableSyntax

      let(:policy) { :admin_merge_request_approval_settings }

      where(:role, :licensed, :admin_mode, :root_group, :allowed) do
        :guest      | true  | nil   | true  | false
        :guest      | false | nil   | true  | false
        :reporter   | true  | nil   | true  | false
        :reporter   | false | nil   | true  | false
        :developer  | true  | nil   | true  | false
        :developer  | false | nil   | true  | false
        :maintainer | true  | nil   | true  | false
        :maintainer | false | nil   | true  | false
        :owner      | true  | nil   | true  | true
        :owner      | true  | nil   | false | false
        :owner      | false | nil   | true  | false
        :admin      | true  | true  | true  | true
        :admin      | true  | true  | false | false
        :admin      | false | true  | true  | false
        :admin      | true  | false | true  | false
        :admin      | false | false | true  | false
      end

      with_them do
        let(:current_user) { public_send(role) }

        before do
          stub_licensed_features(merge_request_approvers: licensed)
          enable_admin_mode!(current_user) if admin_mode
          group.parent = build(:group) unless root_group
        end

        it { is_expected.to(allowed ? be_allowed(policy) : be_disallowed(policy)) }
      end
    end

    describe ':start_trial' do
      using RSpec::Parameterized::TableSyntax

      let(:policy) { :start_trial }

      where(:role, :eligible_for_trial, :admin_mode, :allowed) do
        :guest      | true  | nil   | false
        :guest      | false | nil   | false
        :reporter   | true  | nil   | false
        :reporter   | false | nil   | false
        :developer  | true  | nil   | false
        :developer  | false | nil   | false
        :maintainer | true  | nil   | true
        :maintainer | false | nil   | false
        :owner      | true  | nil   | true
        :owner      | false | nil   | false
        :admin      | true  | true  | true
        :admin      | false | true  | false
        :admin      | true  | false | false
        :admin      | false | false | false
      end

      with_them do
        let(:current_user) { public_send(role) }

        before do
          allow(group).to receive(:eligible_for_trial?).and_return(eligible_for_trial)
          enable_admin_mode!(current_user) if admin_mode
        end

        it { is_expected.to(allowed ? be_allowed(policy) : be_disallowed(policy)) }
      end
    end
  end

  describe 'compliance framework permissions' do
    shared_examples 'compliance framework permissions' do
      using RSpec::Parameterized::TableSyntax

      where(:role, :licensed, :admin_mode, :allowed) do
        :owner      | true  | nil   | true
        :owner      | false | nil   | false
        :admin      | true  | true  | true
        :admin      | true  | false | false
        :maintainer | true  | nil   | false
        :developer  | true  | nil   | false
        :reporter   | true  | nil   | false
        :guest      | true  | nil   | false
      end

      with_them do
        let(:current_user) { public_send(role) }

        before do
          stub_licensed_features(licensed_feature => licensed)
          enable_admin_mode!(current_user) if admin_mode
        end

        it { is_expected.to(allowed ? be_allowed(policy) : be_disallowed(policy)) }
      end
    end

    context ':admin_compliance_framework' do
      let(:policy) { :admin_compliance_framework }
      let(:licensed_feature) { :custom_compliance_frameworks }
      let(:feature_flag_name) { nil }

      include_examples 'compliance framework permissions'
    end

    context ':admin_compliance_pipeline_configuration' do
      let(:policy) { :admin_compliance_pipeline_configuration }
      let(:licensed_feature) { :evaluate_group_level_compliance_pipeline }

      include_examples 'compliance framework permissions'
    end
  end

  describe 'view_devops_adoption' do
    let(:current_user) { owner }
    let(:policy) { :view_group_devops_adoption }

    context 'when license does not include the feature' do
      let(:current_user) { admin }

      before do
        stub_licensed_features(group_level_devops_adoption: false)
        enable_admin_mode!(current_user)
      end

      it { is_expected.to be_disallowed(policy) }
    end

    context 'when license includes the feature' do
      using RSpec::Parameterized::TableSyntax

      where(:role, :allowed) do
        :admin            | true
        :owner            | true
        :maintainer       | true
        :developer        | true
        :reporter         | true
        :guest            | false
        :non_group_member | false
        :auditor          | true
      end

      before do
        stub_licensed_features(group_level_devops_adoption: true)
        enable_admin_mode!(current_user) if current_user.admin?
      end

      with_them do
        let(:current_user) { public_send(role) }

        it { is_expected.to(allowed ? be_allowed(policy) : be_disallowed(policy)) }
      end
    end
  end

  describe 'manage_devops_adoption_namespaces' do
    let(:current_user) { owner }
    let(:policy) { :manage_devops_adoption_namespaces }

    context 'when license does not include the feature' do
      let(:current_user) { admin }

      before do
        stub_licensed_features(group_level_devops_adoption: false)
        enable_admin_mode!(current_user)
      end

      it { is_expected.to be_disallowed(policy) }
    end

    context 'when license includes the feature' do
      using RSpec::Parameterized::TableSyntax

      where(:role, :allowed) do
        :admin            | true
        :owner            | true
        :maintainer       | true
        :developer        | true
        :reporter         | true
        :guest            | false
        :non_group_member | false
      end

      before do
        stub_licensed_features(group_level_devops_adoption: true)
        enable_admin_mode!(current_user) if current_user.admin?
      end

      with_them do
        let(:current_user) { public_send(role) }

        it { is_expected.to(allowed ? be_allowed(policy) : be_disallowed(policy)) }
      end
    end

    context 'when license plan does not include the feature' do
      using RSpec::Parameterized::TableSyntax

      where(:role, :allowed) do
        :admin            | true
        :owner            | false
        :maintainer       | false
        :developer        | false
        :reporter         | false
        :guest            | false
        :non_group_member | false
      end

      before do
        stub_licensed_features(group_level_devops_adoption: true)
        allow(group).to receive(:feature_available?).with(:group_level_devops_adoption).and_return(false)
        enable_admin_mode!(current_user) if current_user.admin?
      end

      with_them do
        let(:current_user) { public_send(role) }

        it { is_expected.to(allowed ? be_allowed(policy) : be_disallowed(policy)) }
      end
    end
  end

  context 'external audit events' do
    let(:current_user) { owner }

    context 'when license is disabled' do
      before do
        stub_licensed_features(external_audit_events: false)
      end

      it { is_expected.to(be_disallowed(:admin_external_audit_events)) }
    end

    context 'when license is enabled' do
      before do
        stub_licensed_features(external_audit_events: true)
      end

      it { is_expected.to(be_allowed(:admin_external_audit_events)) }
    end

    context 'when user is not an owner' do
      let(:current_user) { build_stubbed(:user, :auditor) }

      it { is_expected.to(be_disallowed(:admin_external_audit_events)) }
    end
  end

  describe 'a pending membership' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:user) { create(:user) }

    context 'with a private group' do
      let_it_be(:private_group) { create(:group, :private) }

      subject { described_class.new(user, private_group) }

      where(:role) do
        Gitlab::Access.sym_options_with_owner.keys.map(&:to_sym)
      end

      with_them do
        it 'has permission identical to a private group in which the user is not a member' do
          create(:group_member, :awaiting, role, source: private_group, user: user)

          expect_private_group_permissions_as_if_non_member
        end
      end

      context 'with a project in the group' do
        let_it_be(:project) { create(:project, :private, namespace: private_group) }

        where(:role) do
          Gitlab::Access.sym_options_with_owner.keys.map(&:to_sym)
        end

        with_them do
          it 'has permission identical to a private group in which the user is not a member' do
            create(:group_member, :awaiting, role, source: private_group, user: user)

            expect_private_group_permissions_as_if_non_member
          end
        end
      end
    end

    context 'with a public group' do
      let_it_be(:public_group) { create(:group, :public, :crm_enabled) }

      subject { described_class.new(user, public_group) }

      where(:role) do
        Gitlab::Access.sym_options_with_owner.keys.map(&:to_sym)
      end

      with_them do
        it 'has permission identical to a public group in which the user is not a member' do
          create(:group_member, :awaiting, role, source: public_group, user: user)

          expect_allowed(*public_permissions)
          expect_disallowed(:upload_file)
          expect_disallowed(*reporter_permissions)
          expect_disallowed(*developer_permissions)
          expect_disallowed(*maintainer_permissions)
          expect_disallowed(*owner_permissions)
          expect_disallowed(:read_namespace)
        end
      end
    end

    context 'with a group invited to another group' do
      let_it_be(:group) { create(:group, :public) }
      let_it_be(:other_group) { create(:group, :private) }

      subject { described_class.new(user, other_group) }

      before_all do
        create(:group_group_link, { shared_with_group: group, shared_group: other_group })
      end

      where(:role) do
        Gitlab::Access.sym_options_with_owner.keys.map(&:to_sym)
      end

      with_them do
        it 'has permission to the other group as if the user is not a member' do
          create(:group_member, :awaiting, role, source: group, user: user)

          expect_private_group_permissions_as_if_non_member
        end
      end
    end

    def expect_private_group_permissions_as_if_non_member
      expect_disallowed(*public_permissions)
      expect_disallowed(*guest_permissions)
      expect_disallowed(*reporter_permissions)
      expect_disallowed(*developer_permissions)
      expect_disallowed(*maintainer_permissions)
      expect_disallowed(*owner_permissions)
    end
  end

  describe 'security complience policy' do
    context 'when licensed feature is available' do
      before do
        stub_licensed_features(security_orchestration_policies: false)
      end

      context 'with developer or maintainer role' do
        where(role: %w[maintainer developer])

        with_them do
          let(:current_user) { public_send(role) }

          it { is_expected.to be_disallowed(:read_security_orchestration_policies) }
          it { is_expected.to be_disallowed(:update_security_orchestration_policy_project) }
        end
      end

      context 'with owner role' do
        where(role: %w[owner])

        with_them do
          let(:current_user) { public_send(role) }

          it { is_expected.to be_disallowed(:read_security_orchestration_policies) }
          it { is_expected.to be_disallowed(:update_security_orchestration_policy_project) }
          it { is_expected.to be_disallowed(:modify_security_policy) }
        end
      end
    end

    context 'when licensed feature is available' do
      before do
        stub_licensed_features(security_orchestration_policies: true)
      end

      context 'when security_orchestration_policy_configuration is not present' do
        context 'with developer or maintainer role' do
          where(role: %w[maintainer developer])

          with_them do
            let(:current_user) { public_send(role) }

            it { is_expected.to be_allowed(:read_security_orchestration_policies) }
            it { is_expected.to be_disallowed(:update_security_orchestration_policy_project) }
          end
        end

        context 'with owner role' do
          where(role: %w[owner])

          with_them do
            let(:current_user) { public_send(role) }

            it { is_expected.to be_allowed(:read_security_orchestration_policies) }
            it { is_expected.to be_allowed(:update_security_orchestration_policy_project) }
            it { is_expected.to be_allowed(:modify_security_policy) }
          end
        end
      end

      context 'when security_orchestration_policy_configuration is present' do
        let_it_be(:security_policy_management_project) { create(:project) }
        let(:current_user) { developer }

        before do
          create(:security_orchestration_policy_configuration, project: nil, namespace: group, security_policy_management_project: security_policy_management_project)
        end

        context 'when current_user is developer of security_policy_management_project' do
          before do
            security_policy_management_project.add_developer(developer)
          end

          it { is_expected.to be_allowed(:modify_security_policy) }
        end

        context 'when current_user is not developer of security_policy_management_project' do
          it { is_expected.to be_disallowed(:modify_security_policy) }
        end
      end
    end
  end

  describe 'read_usage_quotas policy' do
    context 'reading usage quotas' do
      using RSpec::Parameterized::TableSyntax

      let(:policy) { :read_usage_quotas }

      where(:role, :admin_mode, :allowed) do
        :owner      | nil   | true
        :admin      | true  | true
        :admin      | false | false
        :maintainer | nil   | false
        :developer  | nil   | false
        :reporter   | nil   | false
        :guest      | nil   | false
      end

      with_them do
        let(:current_user) { public_send(role) }

        before do
          enable_admin_mode!(current_user) if admin_mode
        end

        it { is_expected.to(allowed ? be_allowed(policy) : be_disallowed(policy)) }
      end
    end
  end

  describe 'dependency proxy' do
    context 'feature enabled' do
      before do
        stub_config(dependency_proxy: { enabled: true })
      end

      context 'auditor' do
        let(:current_user) { auditor }

        it { is_expected.to be_allowed(:read_dependency_proxy) }
        it { is_expected.to be_disallowed(:admin_dependency_proxy) }
      end
    end
  end

  describe 'read wiki' do
    context 'feature enabled' do
      before do
        stub_licensed_features(group_wikis: true)
      end

      context 'auditor' do
        let(:current_user) { auditor }

        it { is_expected.to be_allowed(:read_wiki) }
        it { is_expected.to be_disallowed(:admin_wiki) }
      end
    end

    context 'feature disabled' do
      before do
        stub_licensed_features(group_wikis: false)
      end

      context 'auditor' do
        let(:current_user) { auditor }

        it { is_expected.to be_disallowed(:read_wiki) }
        it { is_expected.to be_disallowed(:admin_wiki) }
      end
    end
  end

  describe 'group level compliance dashboard' do
    context 'feature enabled' do
      before do
        stub_licensed_features(group_level_compliance_dashboard: true)
      end

      context 'auditor' do
        let(:current_user) { auditor }

        it { is_expected.to be_allowed(:read_group_compliance_dashboard) }
      end
    end

    context 'feature disabled' do
      before do
        stub_licensed_features(group_level_compliance_dashboard: false)
      end

      context 'auditor' do
        let(:current_user) { auditor }

        it { is_expected.to be_disallowed(:read_group_compliance_dashboard) }
      end
    end
  end

  describe 'user banned from namespace' do
    let_it_be_with_reload(:current_user) { create(:user) }
    let_it_be(:group) { create(:group, :private) }

    subject { described_class.new(current_user, group) }

    before do
      stub_licensed_features(unique_project_download_limit: true)
      group.add_developer(current_user)
    end

    context 'when user is not banned' do
      it { is_expected.to be_allowed(:read_group) }
    end

    context 'when user is banned' do
      before do
        create(:namespace_ban, user: current_user, namespace: group.root_ancestor)
      end

      it { is_expected.to be_disallowed(:read_group) }

      context 'inside a subgroup' do
        let_it_be(:group) { create(:group, :private, :nested) }

        it { is_expected.to be_disallowed(:read_group) }

        context 'as an owner of the subgroup' do
          before do
            group.add_owner(current_user)
          end

          it { is_expected.to be_disallowed(:read_group) }
        end
      end

      context 'as an admin' do
        let_it_be(:current_user) { admin }

        context 'when admin mode is enabled', :enable_admin_mode do
          it { is_expected.to be_allowed(:read_group) }
        end
      end

      context 'when group is public' do
        let_it_be(:group) { create(:group, :public) }

        it { is_expected.to be_disallowed(:read_group) }
      end

      context 'when the limit_unique_project_downloads_per_namespace_user feature flag is disabled' do
        before do
          stub_feature_flags(limit_unique_project_downloads_per_namespace_user: false)
        end

        it { is_expected.to be_allowed(:read_group) }
      end

      context 'when licensed feature unique_project_download_limit is not available' do
        before do
          stub_licensed_features(unique_project_download_limit: false)
        end

        it { is_expected.to be_allowed(:read_group) }
      end
    end
  end

  describe 'ban_group_member' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:user) { create(:user) }

    let(:group) { create(:group) }

    subject(:policy) { described_class.new(user, group) }

    where(:unique_project_download_limit_enabled, :is_owner, :enabled) do
      false | false | false
      false | true  | false
      true  | false | false
      true  | true  | true
    end

    with_them do
      before do
        allow(group).to receive(:unique_project_download_limit_enabled?)
          .and_return(unique_project_download_limit_enabled)
        group.add_owner(user) if is_owner
      end

      it 'has the correct value' do
        if enabled
          expect(policy).to be_allowed(:ban_group_member)
        else
          expect(policy).to be_disallowed(:ban_group_member)
        end
      end
    end
  end

  describe 'group cicd runners' do
    context 'auditor' do
      let(:current_user) { auditor }

      it { is_expected.to be_allowed(:read_group_runners) }
      it { is_expected.to be_allowed(:read_group_all_available_runners) }
      it { is_expected.to be_disallowed(:admin_group_runners) }
      it { is_expected.to be_disallowed(:register_group_runners) }
    end
  end

  describe 'group container registry' do
    context 'auditor' do
      let(:current_user) { auditor }

      it { is_expected.to be_allowed(:read_container_image) }
      it { is_expected.to be_disallowed(:admin_container_image) }
    end
  end

  describe 'admin_service_accounts' do
    context 'when the feature is not enabled' do
      let(:current_user) { owner }

      it { is_expected.to be_disallowed(:admin_service_accounts) }
    end

    context 'when feature is enabled' do
      before do
        stub_licensed_features(service_accounts: true)
      end

      context 'when the user is a maintainer' do
        let(:current_user) { maintainer }

        it { is_expected.to be_disallowed(:admin_service_accounts) }
      end

      context 'when the user is an owner' do
        let(:current_user) { owner }

        it { is_expected.to be_allowed(:admin_service_accounts) }
      end
    end
  end
end
