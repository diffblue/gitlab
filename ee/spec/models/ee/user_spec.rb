# frozen_string_literal: true

require 'spec_helper'

RSpec.describe User, feature_category: :system_access do
  subject(:user) { described_class.new }

  describe 'user creation' do
    describe 'with defaults' do
      it "applies defaults to user" do
        expect(user.group_view).to eq('details')
      end
    end
  end

  describe 'delegations' do
    it { is_expected.to delegate_method(:shared_runners_minutes_limit).to(:namespace) }
    it { is_expected.to delegate_method(:shared_runners_minutes_limit=).to(:namespace).with_arguments(133) }
    it { is_expected.to delegate_method(:onboarding_step_url=).to(:user_detail).with_arguments('_url_').allow_nil }
    it { is_expected.to delegate_method(:code_suggestions_enabled?).to(:namespace) }
    it { is_expected.to delegate_method(:code_suggestions).to(:namespace) }
    it { is_expected.to delegate_method(:code_suggestions=).to(:namespace).with_arguments(true) }
  end

  describe 'associations' do
    subject { build(:user) }

    it { is_expected.to have_many(:vulnerability_feedback) }
    it { is_expected.to have_many(:path_locks).dependent(:destroy) }
    it { is_expected.to have_many(:users_security_dashboard_projects) }
    it { is_expected.to have_many(:security_dashboard_projects) }
    it { is_expected.to have_many(:board_preferences) }
    it { is_expected.to have_many(:boards_epic_user_preferences).class_name('Boards::EpicUserPreference') }
    it { is_expected.to have_many(:user_permission_export_uploads) }
    it { is_expected.to have_many(:oncall_participants).class_name('IncidentManagement::OncallParticipant') }
    it { is_expected.to have_many(:oncall_rotations).class_name('IncidentManagement::OncallRotation').through(:oncall_participants) }
    it { is_expected.to have_many(:oncall_schedules).class_name('IncidentManagement::OncallSchedule').through(:oncall_rotations) }
    it { is_expected.to have_many(:escalation_rules).class_name('IncidentManagement::EscalationRule') }
    it { is_expected.to have_many(:escalation_policies).class_name('IncidentManagement::EscalationPolicy').through(:escalation_rules) }
    it { is_expected.to have_many(:epic_board_recent_visits).inverse_of(:user) }
    it { is_expected.to have_many(:vulnerability_state_transitions).class_name('Vulnerabilities::StateTransition').with_foreign_key(:author_id).inverse_of(:author) }
    it { is_expected.to have_many(:deployment_approvals) }
    it { is_expected.to have_many(:namespace_bans).class_name('Namespaces::NamespaceBan') }
    it { is_expected.to have_many(:dependency_list_exports).class_name('Dependencies::DependencyListExport') }
    it { is_expected.to have_many(:elevated_members).class_name('Member') }
    it { is_expected.to have_many(:assigned_add_ons).class_name('GitlabSubscriptions::UserAddOnAssignment').inverse_of(:user) }
  end

  describe 'nested attributes' do
    it { is_expected.to respond_to(:namespace_attributes=) }
  end

  describe 'validations' do
    it 'does not allow a user to be both an auditor and an admin' do
      user = build(:user, :admin, :auditor)

      expect(user).to be_invalid
    end
  end

  describe "scopes" do
    describe ".non_ldap" do
      it "retuns non-ldap user" do
        described_class.delete_all
        create(:user)
        ldap_user = create(:omniauth_user, provider: "ldapmain")
        create(:omniauth_user, provider: "gitlab")

        users = described_class.non_ldap

        expect(users.count).to eq(2)
        expect(users.detect { |user| user.username == ldap_user.username }).to be_nil
      end
    end

    describe '.excluding_guests' do
      let!(:user_without_membership) { create(:user).id }
      let!(:project_guest_user)      { create(:project_member, :guest).user_id }
      let!(:project_reporter_user)   { create(:project_member, :reporter).user_id }
      let!(:group_guest_user)        { create(:group_member, :guest).user_id }
      let!(:group_reporter_user)     { create(:group_member, :reporter).user_id }

      it 'exclude users with a Guest role in a Project/Group' do
        user_ids = described_class.excluding_guests.pluck(:id)

        expect(user_ids).to include(project_reporter_user)
        expect(user_ids).to include(group_reporter_user)

        expect(user_ids).not_to include(user_without_membership)
        expect(user_ids).not_to include(project_guest_user)
        expect(user_ids).not_to include(group_guest_user)
      end
    end

    describe 'with_invalid_expires_at_tokens' do
      it 'only includes users with invalid tokens' do
        valid_pat = create(:personal_access_token, expires_at: 7.days.from_now)
        invalid_pat = create(:personal_access_token, expires_at: 20.days.from_now)

        users_with_invalid_tokens = described_class.with_invalid_expires_at_tokens(15.days.from_now)

        expect(users_with_invalid_tokens).to contain_exactly(invalid_pat.user)
        expect(users_with_invalid_tokens).not_to include valid_pat.user
      end
    end

    describe '.guests_with_elevating_role' do
      let(:group) { create(:group) }
      let(:member_role_elevating) { create(:member_role, :guest, namespace: group) }
      let(:member_role_basic) { create(:member_role, :guest, namespace: group) }
      let(:expected_user) { create(:group_member, :guest, source: group, member_role: member_role_elevating).user }

      before do
        user = create(:user)
        [
          expected_user,
          create(:group_member, :developer, source: group).user,
          _elevated_guest_who_is_also_developer = create(:group_member, :guest, user: user, source: group, member_role: member_role_elevating).user,
          create(:group_member, :guest, source: group, member_role: member_role_basic).user,
          create(:group_member, :developer, user: user).user
        ].each do |user|
          Users::UpdateHighestMemberRoleService.new(user).execute
        end
      end

      it 'returns only guests with elevated role' do
        expect(MemberRole).to receive(:elevating).at_least(:once).and_return(MemberRole.where(id: member_role_elevating.id))

        expect(described_class.guests_with_elevating_role).to contain_exactly(expected_user)
      end
    end

    describe '.managed_by' do
      let!(:group) { create(:group_with_managed_accounts) }
      let!(:managed_users) { create_list(:user, 2, managing_group: group) }

      it 'returns users managed by the specified group' do
        expect(described_class.managed_by(group)).to match_array(managed_users)
      end
    end

    describe '.unconfirmed_and_created_before' do
      it 'returns unconfirmed, active, human users who never signed in and were created before timestamp passed in' do
        cut_off_datetime = 7.days.ago
        _confirmed_user_created_before_cut_off = create(:user, confirmed_at: Time.current, created_at: cut_off_datetime - 1.day)
        _confirmed_user_created_after_cut_off = create(:user, confirmed_at: Time.current, created_at: cut_off_datetime + 1.day)
        _unconfirmed_user_created_after_cut_off = create(:user, :unconfirmed, created_at: cut_off_datetime + 1.day)
        _unconfirmed_bot_user_created_before_cut_off = create(:user, :bot, :unconfirmed, created_at: cut_off_datetime - 1.day)
        _deactivated_user_created_before_cut_off = create(:user, :unconfirmed, :deactivated, created_at: cut_off_datetime - 1.day)
        _unconfirmed_user_who_signed_in = create(:user, :unconfirmed, created_at: cut_off_datetime - 1.day, sign_in_count: 1)
        unconfirmed_user_created_before_cut_off = create(:user, :unconfirmed, created_at: cut_off_datetime - 1.day)

        expect(described_class.unconfirmed_and_created_before(cut_off_datetime)).to match_array(
          [unconfirmed_user_created_before_cut_off]
        )
      end
    end
  end

  describe 'after_create' do
    describe '#perform_user_cap_check' do
      let(:new_user_signups_cap) { nil }

      before do
        allow(Gitlab::CurrentSettings).to receive(:new_user_signups_cap).and_return(new_user_signups_cap)
      end

      context 'when user cap is not set' do
        it 'does not enqueue SetUserStatusBasedOnUserCapSettingWorker' do
          expect(SetUserStatusBasedOnUserCapSettingWorker).not_to receive(:perform_async)

          create(:user, state: 'blocked_pending_approval')
        end
      end

      context 'when user cap is set' do
        let(:new_user_signups_cap) { 3 }

        context 'when user signup cap has been reached' do
          let!(:users) { create_list(:user, 3) }

          it 'enqueues SetUserStatusBasedOnUserCapSettingWorker' do
            expect(SetUserStatusBasedOnUserCapSettingWorker).to receive(:perform_async).once

            create(:user, state: 'blocked_pending_approval')
          end

          context 'when the user is already active' do
            it 'does not enqueue SetUserStatusBasedOnUserCapSettingWorker' do
              expect(SetUserStatusBasedOnUserCapSettingWorker).not_to receive(:perform_async)

              create(:user, state: 'active')
            end
          end
        end

        context 'when user signup cap has not been reached' do
          let!(:users) { create_list(:user, 2) }

          it 'does not enqueue SetUserStatusBasedOnUserCapSettingWorker' do
            expect(SetUserStatusBasedOnUserCapSettingWorker).not_to receive(:perform_async)

            create(:user, state: 'blocked_pending_approval')
          end
        end
      end
    end
  end

  describe 'after_update' do
    describe '#email_changed_hook' do
      context 'for a new user' do
        let(:user) { build(:user) }

        it 'is not triggered' do
          expect(user).not_to receive(:email_changed_hook)

          user.save!
        end
      end

      context 'for an existing user' do
        let(:user) { create(:user) }

        context 'when skip_reconfirmation is disabled' do
          context 'when email change is not confirmed' do
            it 'is not triggered' do
              expect(user).not_to receive(:email_changed_hook)

              user.update!(email: 'new-email@example.com')
            end
          end

          context 'when email change is confirmed' do
            it 'is triggered' do
              user.update!(email: 'new-email@example.com')

              expect(user).to receive(:email_changed_hook)
              user.confirm
            end
          end
        end

        context 'when skip_reconfirmation is enabled' do
          before do
            user.skip_reconfirmation!
          end

          context 'when email was not changed' do
            it 'is not triggered' do
              expect(user).not_to receive(:email_changed_hook)

              user.update!(name: 'New name')
            end
          end

          context 'when email was changed' do
            it 'is triggered' do
              expect(user).to receive(:email_changed_hook)

              user.update!(email: 'new-email@example.com')
            end

            context 'when user is not an enterprise user' do
              it 'does not schedule Groups::EnterpriseUsers::DisassociateWorker' do
                expect(Groups::EnterpriseUsers::DisassociateWorker).not_to receive(:perform_async)

                user.update!(email: 'new-email@example.com')
              end
            end

            context 'when user is an enterprise user' do
              let(:user) { create(:user, :enterprise_user) }

              it 'schedules Groups::EnterpriseUsers::DisassociateWorker' do
                expect(Groups::EnterpriseUsers::DisassociateWorker).to receive(:perform_async).with(user.id)

                user.update!(email: 'new-email@example.com')
              end
            end
          end
        end
      end
    end
  end

  describe '.find_by_smartcard_identity' do
    let!(:user) { create(:user) }
    let!(:smartcard_identity) { create(:smartcard_identity, user: user) }

    it 'returns the user' do
      expect(described_class.find_by_smartcard_identity(
        smartcard_identity.subject, smartcard_identity.issuer
      )).to eq(user)
    end
  end

  describe 'reactivating a deactivated user' do
    let(:user) { create(:user, name: 'John Smith') }

    context 'a deactivated user' do
      before do
        user.deactivate
      end

      it 'can be activated' do
        user.activate

        expect(user.active?).to be_truthy
      end

      context 'when user cap is reached' do
        before do
          allow(described_class).to receive(:user_cap_reached?).and_return true
        end

        it 'cannot be activated' do
          user.activate

          expect(user.active?).not_to be_truthy
          expect(user.blocked_pending_approval?).to be_truthy
        end
      end
    end
  end

  describe 'the GitLab_Auditor_User add-on' do
    context 'creating an auditor user' do
      it "does not allow creating an auditor user if the addon isn't enabled" do
        stub_licensed_features(auditor_user: false)

        expect(build(:user, :auditor)).to be_invalid
      end

      it "does not allow creating an auditor user if no license is present" do
        allow(License).to receive(:current).and_return nil

        expect(build(:user, :auditor)).to be_invalid
      end

      it "allows creating an auditor user if the addon is enabled" do
        stub_licensed_features(auditor_user: true)

        expect(build(:user, :auditor)).to be_valid
      end

      it "allows creating a regular user if the addon isn't enabled" do
        stub_licensed_features(auditor_user: false)

        expect(build(:user)).to be_valid
      end
    end

    describe '#auditor?' do
      it "returns true for an auditor user if the addon is enabled" do
        stub_licensed_features(auditor_user: true)

        expect(build(:user, :auditor)).to be_auditor
      end

      it "returns false for an auditor user if the addon is not enabled" do
        stub_licensed_features(auditor_user: false)

        expect(build(:user, :auditor)).not_to be_auditor
      end

      it "returns false for an auditor user if a license is not present" do
        allow(License).to receive(:current).and_return nil

        expect(build(:user, :auditor)).not_to be_auditor
      end

      it "returns false for a non-auditor user even if the addon is present" do
        stub_licensed_features(auditor_user: true)

        expect(build(:user)).not_to be_auditor
      end
    end
  end

  describe '#access_level=' do
    let(:user) { build(:user) }

    before do
      # `auditor?` returns true only when the user is an auditor _and_ the auditor license
      # add-on is present. We aren't testing this here, so we can assume that the add-on exists.
      stub_licensed_features(auditor_user: true)
    end

    it "does not set 'auditor' for an invalid access level" do
      user.access_level = :invalid_access_level

      expect(user.auditor).to be false
    end

    it "does not set 'auditor' for admin level" do
      user.access_level = :admin

      expect(user.auditor).to be false
    end

    it "assigns the 'auditor' access level" do
      user.access_level = :auditor

      expect(user.access_level).to eq(:auditor)
      expect(user.admin).to be false
      expect(user.auditor).to be true
    end

    it "assigns the 'auditor' access level" do
      user.access_level = :regular

      expect(user.access_level).to eq(:regular)
      expect(user.admin).to be false
      expect(user.auditor).to be false
    end

    it "clears the 'admin' access level when a user is made an auditor" do
      user.access_level = :admin
      user.access_level = :auditor

      expect(user.access_level).to eq(:auditor)
      expect(user.admin).to be false
      expect(user.auditor).to be true
    end

    it "clears the 'auditor' access level when a user is made an admin" do
      user.access_level = :auditor
      user.access_level = :admin

      expect(user.access_level).to eq(:admin)
      expect(user.admin).to be true
      expect(user.auditor).to be false
    end

    it "doesn't clear existing 'auditor' access levels when an invalid access level is passed in" do
      user.access_level = :auditor
      user.access_level = :invalid_access_level

      expect(user.access_level).to eq(:auditor)
      expect(user.admin).to be false
      expect(user.auditor).to be true
    end
  end

  describe '#can_read_all_resources?' do
    it 'returns true for auditor user' do
      user = build(:user, :auditor)

      expect(user.can_read_all_resources?).to be_truthy
    end
  end

  describe '#can_admin_all_resources?' do
    it 'returns false for auditor user' do
      user = build(:user, :auditor)

      expect(user.can_admin_all_resources?).to be_falsy
    end
  end

  describe '#forget_me!' do
    subject { create(:user, remember_created_at: Time.current) }

    it 'clears remember_created_at' do
      subject.forget_me!

      expect(subject.reload.remember_created_at).to be_nil
    end

    it 'does not clear remember_created_at when in a GitLab read-only instance' do
      allow(Gitlab::Database).to receive(:read_only?) { true }

      expect { subject.forget_me! }.not_to change(subject, :remember_created_at)
    end
  end

  describe '#remember_me!' do
    subject { create(:user, remember_created_at: nil) }

    it 'updates remember_created_at' do
      subject.remember_me!

      expect(subject.reload.remember_created_at).not_to be_nil
    end

    it 'does not update remember_created_at when in a Geo read-only instance' do
      allow(Gitlab::Database).to receive(:read_only?) { true }

      expect { subject.remember_me! }.not_to change(subject, :remember_created_at)
    end
  end

  describe '#email_opted_in_source' do
    context 'for GitLab.com' do
      let(:user) { build(:user, email_opted_in_source_id: 1) }

      it 'returns GitLab.com' do
        expect(user.email_opted_in_source).to eq('GitLab.com')
      end
    end

    context 'for nil source id' do
      let(:user) { build(:user, email_opted_in_source_id: nil) }

      it 'returns blank' do
        expect(user.email_opted_in_source).to be_blank
      end
    end

    context 'for non-existent source id' do
      let(:user) { build(:user, email_opted_in_source_id: 2) }

      it 'returns blank' do
        expect(user.email_opted_in_source).to be_blank
      end
    end
  end

  describe '#available_custom_project_templates' do
    let(:user) { create(:user) }

    it 'returns an empty relation if group is not set' do
      expect(user.available_custom_project_templates.empty?).to be_truthy
    end

    context 'when group with custom project templates is set' do
      let(:group) { create(:group) }

      before do
        stub_ee_application_setting(custom_project_templates_group_id: group.id)
      end

      it 'returns an empty relation if group has no available project templates' do
        expect(group.projects.empty?).to be true
        expect(user.available_custom_project_templates.empty?).to be true
      end

      context 'when group has custom project templates' do
        let!(:private_project) { create :project, :private, namespace: group, name: 'private_project' }
        let!(:internal_project) { create :project, :internal, namespace: group, name: 'internal_project' }
        let!(:public_project) { create :project, :metrics_dashboard_enabled, :public, namespace: group, name: 'public_project' }
        let!(:public_project_two) { create :project, :metrics_dashboard_enabled, :public, namespace: group, name: 'public_project_second' }

        it 'returns public projects' do
          expect(user.available_custom_project_templates).to include public_project
        end

        context 'returns private projects if user' do
          it 'is a member of the project' do
            expect(user.available_custom_project_templates).not_to include private_project

            private_project.add_developer(user)

            expect(user.available_custom_project_templates).to include private_project
          end

          it 'is a member of the group' do
            expect(user.available_custom_project_templates).not_to include private_project

            group.add_developer(user)

            expect(user.available_custom_project_templates).to include private_project
          end
        end

        context 'returns internal projects if user' do
          it 'is a member of the project' do
            expect(user.available_custom_project_templates).not_to include internal_project

            internal_project.add_developer(user)

            expect(user.available_custom_project_templates).to include internal_project
          end

          it 'is a member of the group' do
            expect(user.available_custom_project_templates).not_to include internal_project

            group.add_developer(user)

            expect(user.available_custom_project_templates).to include internal_project
          end
        end

        it 'allows to search available project templates by name' do
          projects = user.available_custom_project_templates(search: 'publi')

          expect(projects.count).to eq 2
          expect(projects.first).to eq public_project
        end

        it 'filters by project ID' do
          projects = user.available_custom_project_templates(project_id: public_project.id)

          expect(projects.count).to eq 1
          expect(projects).to match_array([public_project])

          projects = user.available_custom_project_templates(project_id: [public_project.id, public_project_two.id])

          expect(projects.count).to eq 2
          expect(projects).to match_array([public_project, public_project_two])
        end

        it 'does not return inaccessible projects' do
          projects = user.available_custom_project_templates(project_id: private_project.id)

          expect(projects.count).to eq 0
        end
      end

      it 'returns project with disabled features' do
        public_project = create(:project, :public, :metrics_dashboard_enabled, namespace: group)
        disabled_issues_project = create(:project, :public, :metrics_dashboard_enabled, :issues_disabled, namespace: group)

        expect(user.available_custom_project_templates).to include public_project
        expect(user.available_custom_project_templates).to include disabled_issues_project
      end

      it 'does not return project with private issues' do
        accessible_project = create(:project, :public, :metrics_dashboard_enabled, namespace: group)
        restricted_features_project = create(:project, :public, :metrics_dashboard_enabled, :issues_private, namespace: group)

        expect(user.available_custom_project_templates).to include accessible_project
        expect(user.available_custom_project_templates).not_to include restricted_features_project
      end
    end
  end

  describe '#available_subgroups_with_custom_project_templates' do
    let(:user) { create(:user) }

    context 'without Groups with custom project templates' do
      before do
        group = create(:group)

        group.add_maintainer(user)
      end

      it 'returns an empty collection' do
        expect(user.available_subgroups_with_custom_project_templates).to be_empty
      end
    end

    context 'with Groups with custom project templates' do
      let!(:group_1) { create(:group, name: 'group-1') }
      let!(:group_2) { create(:group, name: 'group-2') }
      let!(:group_3) { create(:group, name: 'group-3') }

      let!(:subgroup_1) { create(:group, parent: group_1, name: 'subgroup-1') }
      let!(:subgroup_2) { create(:group, parent: group_2, name: 'subgroup-2') }
      let!(:subgroup_3) { create(:group, parent: group_3, name: 'subgroup-3') }

      before do
        group_1.update!(custom_project_templates_group_id: subgroup_1.id)
        group_2.update!(custom_project_templates_group_id: subgroup_2.id)
        group_3.update!(custom_project_templates_group_id: subgroup_3.id)

        create(:project, namespace: subgroup_1)
        create(:project, namespace: subgroup_2)
      end

      context 'when the access level of the user is below the required one' do
        before do
          group_1.add_reporter(user)
        end

        it 'returns an empty collection' do
          expect(user.available_subgroups_with_custom_project_templates).to be_empty
        end
      end

      context 'when the access level of the user is the correct' do
        before do
          group_1.add_developer(user)
          group_2.add_maintainer(user)
          group_3.add_developer(user)
        end

        context 'when a Group ID is passed' do
          it 'returns a single Group' do
            groups = user.available_subgroups_with_custom_project_templates(group_1.id)

            expect(groups.to_a.size).to eq(1)
            expect(groups.take.name).to eq('subgroup-1')
          end
        end

        context 'when a Group ID is not passed' do
          it 'returns all available Groups' do
            groups = user.available_subgroups_with_custom_project_templates

            expect(groups.to_a.size).to eq(2)
            expect(groups.map(&:name)).to include('subgroup-1', 'subgroup-2')
          end

          it 'excludes Groups with the configured setting but without projects' do
            groups = user.available_subgroups_with_custom_project_templates

            expect(groups.map(&:name)).not_to include('subgroup-3')
          end
        end

        context 'when namespace plan is checked', :saas do
          before do
            create(:gitlab_subscription, namespace: group_1, hosted_plan: create(:bronze_plan))
            create(:gitlab_subscription, namespace: group_2, hosted_plan: create(:ultimate_plan))
            allow(Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?) { true }
          end

          it 'returns groups on ultimate or premium plans' do
            groups = user.available_subgroups_with_custom_project_templates

            expect(groups.to_a.size).to eq(1)
            expect(groups.map(&:name)).to include('subgroup-2')
          end
        end
      end
    end
  end

  describe '#roadmap_layout' do
    context 'not set' do
      subject { build(:user, roadmap_layout: nil) }

      it 'returns default value' do
        expect(subject.roadmap_layout).to eq(EE::User::DEFAULT_ROADMAP_LAYOUT)
      end
    end

    context 'set' do
      subject { build(:user, roadmap_layout: 'quarters') }

      it 'returns set value' do
        expect(subject.roadmap_layout).to eq('quarters')
      end
    end
  end

  describe '#group_sso?' do
    subject(:user) { create(:user) }

    it 'is false without a saml_provider' do
      expect(subject.group_sso?(nil)).to be_falsey
      expect(subject.group_sso?(create(:group))).to be_falsey
    end

    context 'with linked identity' do
      let!(:identity) { create(:group_saml_identity, user: user) }
      let(:saml_provider) { identity.saml_provider }
      let(:group) { saml_provider.group }

      context 'without preloading' do
        it 'returns true' do
          expect(subject.group_sso?(group)).to be_truthy
        end

        it 'does not cause ActiveRecord to loop through identites' do
          create(:group_saml_identity, user: user)

          expect(Identity).not_to receive(:instantiate)

          subject.group_sso?(group)
        end
      end

      context 'when identities and saml_providers pre-loaded' do
        before do
          ActiveRecord::Associations::Preloader.new(records: [subject], associations: { group_saml_identities: :saml_provider }).call
        end

        it 'returns true' do
          expect(subject.group_sso?(group)).to be_truthy
        end

        it 'does not trigger additional database queries' do
          expect { subject.group_sso?(group) }.not_to exceed_query_limit(0)
        end
      end
    end
  end

  describe '.limit_to_saml_provider' do
    let_it_be(:user1) { create(:user) }
    let_it_be(:user2) { create(:user) }

    it 'returns all users when SAML provider is nil' do
      rel = described_class.limit_to_saml_provider(nil)

      expect(rel).to include(user1, user2)
    end

    it 'returns only the users who have an identity that belongs to the given SAML provider' do
      create(:user)
      group = create(:group)
      saml_provider = create(:saml_provider, group: group)
      create(:identity, saml_provider: saml_provider, user: user1)
      create(:identity, saml_provider: saml_provider, user: user2)
      create(:identity, user: create(:user))

      rel = described_class.limit_to_saml_provider(saml_provider.id)

      expect(rel).to contain_exactly(user1, user2)
    end
  end

  describe '.billable' do
    let_it_be(:bot_user) { create(:user, :bot) }
    let_it_be(:service_account) { create(:user, :service_account) }
    let_it_be(:regular_user) { create(:user) }
    let_it_be(:project_reporter_user) { create(:project_member, :reporter).user }
    let_it_be(:project_guest_user) { create(:project_member, :guest).user }
    let_it_be(:group) { create(:group) }
    let_it_be(:member_role_elevating) { create(:member_role, :guest, namespace: group) }
    let_it_be(:member_role_basic) { create(:member_role, :guest, namespace: group) }
    let_it_be(:guest_with_elevated_role) { create(:group_member, :guest, source: group, member_role: member_role_elevating).user }
    let_it_be(:guest_without_elevated_role) { create(:group_member, :guest, source: group, member_role: member_role_basic).user }

    subject(:users) { described_class.billable }

    context 'with guests' do
      it 'validates the sql matches the specific index we have' do
        expected_sql = <<~SQL
          SELECT "users".* FROM "users"
          WHERE ("users"."state" IN ('active'))
          AND
          "users"."user_type" IN (0, 6, 4, 13)
          AND
          "users"."user_type" IN (0, 4, 5)
        SQL

        expect(users.to_sql.squish).to eq(expected_sql.squish), "query was changed. Please ensure query is covered with an index and adjust this test case"
      end

      it 'returns users' do
        expect(users).to include(project_reporter_user)
        expect(users).to include(project_guest_user)
        expect(users).to include(regular_user)
        expect(users).to include(guest_with_elevated_role)
        expect(users).to include(guest_without_elevated_role)

        expect(users).not_to include(bot_user)
        expect(users).not_to include(service_account)
      end
    end

    context 'without guests' do
      before do
        license = double('License', exclude_guests_from_active_count?: true)
        allow(License).to receive(:current) { license }
      end

      context 'with elevated_guests FF disabled' do
        before do
          stub_feature_flags(elevated_guests: false)
        end

        it 'validates the sql matches the specific index we have' do
          expected_sql = <<~SQL
            SELECT "users".* FROM "users"
            WHERE ("users"."state" IN ('active'))
            AND
            "users"."user_type" IN (0, 6, 4, 13)
            AND
            "users"."user_type" IN (0, 4, 5)
            AND
            (EXISTS (SELECT 1 FROM "members"
              WHERE "members"."user_id" = "users"."id"
              AND (members.access_level > 10)))
          SQL

          expect(users.to_sql.squish).to eq(expected_sql.squish), "query was changed. Please ensure query is covered with an index and adjust this test case"
        end

        it 'returns users' do
          expect(users).to include(project_reporter_user)

          expect(users).not_to include(regular_user)
          expect(users).not_to include(project_guest_user)
          expect(users).not_to include(bot_user)
          expect(users).not_to include(service_account)
        end

        context 'with elevating role' do
          it 'returns users with elevated roles' do
            expect(MemberRole).not_to receive(:elevating)

            expect(users).not_to include(guest_with_elevated_role)
            expect(users).not_to include(guest_without_elevated_role)
          end
        end
      end

      context 'with elevated_guests FF enabled' do
        before do
          stub_feature_flags(elevated_guests: true)
        end

        context 'with elevating role' do
          it 'returns users with elevated roles' do
            expect(MemberRole).to receive(:elevating).at_least(:once).and_return(MemberRole.where(id: member_role_elevating.id))

            expect(users).to include(guest_with_elevated_role)
            expect(users).not_to include(guest_without_elevated_role)
          end
        end
      end
    end
  end

  describe '#group_managed_account?' do
    subject { user.group_managed_account? }

    context 'when user has managing group linked' do
      before do
        user.managing_group = Group.new
      end

      it { is_expected.to eq true }
    end

    context 'when user has no linked managing group' do
      it { is_expected.to eq false }
    end
  end

  describe '#managed_by?' do
    let(:group) { create :group }
    let(:owner) { create :user }
    let(:member1) { create :user }
    let(:member2) { create :user }

    before do
      group.add_owner(owner)
      group.add_developer(member1)
      group.add_developer(member2)
    end

    context 'when a normal user account' do
      it 'returns false' do
        expect(member1.managed_by?(owner)).to be_falsey
        expect(member1.managed_by?(member2)).to be_falsey
      end
    end

    context 'when a group managed account' do
      let(:group) { create :group_with_managed_accounts }

      before do
        member1.update!(managing_group: group)
      end

      it 'returns true with group managed account owner' do
        expect(member1.managed_by?(owner)).to be_truthy
      end

      it 'returns false with a regular user account' do
        expect(member1.managed_by?(member2)).to be_falsey
      end
    end
  end

  describe '#password_required?' do
    shared_examples 'does not require password to be present' do
      it { expect(user).not_to validate_presence_of(:password) }
      it { expect(user).not_to validate_presence_of(:password_confirmation) }
    end

    context 'when user has managing group linked' do
      before do
        user.managing_group = Group.new
      end

      it_behaves_like 'does not require password to be present'
    end

    context 'when user is a service account user' do
      before do
        user.user_type = 'service_account'
      end

      it_behaves_like 'does not require password to be present'
    end
  end

  describe '#allow_password_authentication_for_web?' do
    context 'when user has managing group linked' do
      before do
        user.managing_group = build(:group)
      end

      it 'is false' do
        expect(user.allow_password_authentication_for_web?).to eq false
      end
    end

    context 'when user is provisioned by group' do
      before do
        user.user_detail.provisioned_by_group = build(:group)
      end

      it 'is false' do
        expect(user.allow_password_authentication_for_web?).to eq false
      end

      context 'with feature flag switched off' do
        before do
          stub_feature_flags(block_password_auth_for_saml_users: false)
        end

        it 'is true' do
          expect(user.allow_password_authentication_for_web?).to eq true
        end
      end
    end
  end

  describe '#allow_password_authentication_for_git?' do
    context 'when user has managing group linked' do
      before do
        user.managing_group = build(:group)
      end

      it 'is false' do
        expect(user.allow_password_authentication_for_git?).to eq false
      end
    end

    context 'when user is provisioned by group' do
      before do
        user.user_detail.provisioned_by_group = build(:group)
      end

      it 'is false' do
        expect(user.allow_password_authentication_for_git?).to eq false
      end

      context 'with feature flag switched off' do
        before do
          stub_feature_flags(block_password_auth_for_saml_users: false)
        end

        it 'is true' do
          expect(user.allow_password_authentication_for_git?).to eq true
        end
      end
    end
  end

  describe '#password_expired_if_applicable?' do
    let(:user) { build(:user, password_expires_at: password_expires_at) }

    subject { user.password_expired_if_applicable? }

    shared_examples 'password expired not applicable' do
      context 'when password_expires_at is not set' do
        let(:password_expires_at) {}

        it 'returns false' do
          is_expected.to be_falsey
        end
      end

      context 'when password_expires_at is in the past' do
        let(:password_expires_at) { 1.minute.ago }

        it 'returns false' do
          is_expected.to be_falsey
        end
      end

      context 'when password_expires_at is in the future' do
        let(:password_expires_at) { 1.minute.from_now }

        it 'returns false' do
          is_expected.to be_falsey
        end
      end
    end

    context 'when password_automatically_set is true' do
      context 'with a SCIM identity' do
        let_it_be(:scim_identity) { create(:scim_identity, active: true) }
        let_it_be(:user) { scim_identity.user }

        it_behaves_like 'password expired not applicable'
      end

      context 'with a SAML identity' do
        let_it_be(:saml_identity) { create(:group_saml_identity) }
        let_it_be(:user) { saml_identity.user }

        it_behaves_like 'password expired not applicable'
      end

      context 'with a smartcard identity' do
        let_it_be(:smartcard_identity) { create(:smartcard_identity) }
        let_it_be(:user) { smartcard_identity.user }

        it_behaves_like 'password expired not applicable'
      end
    end
  end

  describe '#user_authorized_by_provisioning_group?' do
    context 'when user is provisioned by group' do
      let(:group) { build(:group) }

      before do
        user.user_detail.provisioned_by_group = group
      end

      it 'is true' do
        expect(user.user_authorized_by_provisioning_group?).to eq true
      end

      context 'with feature flag switched off' do
        before do
          stub_feature_flags(block_password_auth_for_saml_users: false)
        end

        it 'is false' do
          expect(user.user_authorized_by_provisioning_group?).to eq false
        end
      end

      context 'with feature flag switched on for particular groups' do
        before do
          stub_feature_flags(block_password_auth_for_saml_users: false)
        end

        it 'is false when provisioned by group without feature flag' do
          stub_feature_flags(block_password_auth_for_saml_users: create(:group))

          expect(user.user_authorized_by_provisioning_group?).to eq false
        end

        it 'is true when provisioned by group with feature flag' do
          stub_feature_flags(block_password_auth_for_saml_users: group)

          expect(user.user_authorized_by_provisioning_group?).to eq true
        end
      end
    end

    context 'when user is not provisioned by group' do
      it 'is false' do
        expect(user.user_authorized_by_provisioning_group?).to eq false
      end

      context 'with feature flag switched off' do
        before do
          stub_feature_flags(block_password_auth_for_saml_users: false)
        end

        it 'is false' do
          expect(user.user_authorized_by_provisioning_group?).to eq false
        end
      end
    end
  end

  describe '#authorized_by_provisioning_group?' do
    let_it_be(:group) { create(:group) }

    context 'when user is provisioned by group' do
      before do
        user.user_detail.provisioned_by_group = group
      end

      it 'is true' do
        expect(user.authorized_by_provisioning_group?(group)).to eq true
      end

      context 'when other group is provided' do
        it 'is false' do
          expect(user.authorized_by_provisioning_group?(create(:group))).to eq false
        end
      end

      context 'with feature flag switched off' do
        before do
          stub_feature_flags(block_password_auth_for_saml_users: false)
        end

        it 'is false' do
          expect(user.authorized_by_provisioning_group?(group)).to eq false
        end
      end
    end

    context 'when user is not provisioned by group' do
      it 'is false' do
        expect(user.authorized_by_provisioning_group?(group)).to eq false
      end

      context 'with feature flag switched off' do
        before do
          stub_feature_flags(block_password_auth_for_saml_users: false)
        end

        it 'is false' do
          expect(user.authorized_by_provisioning_group?(group)).to eq false
        end
      end
    end
  end

  describe '#enterprise_user_of_group?' do
    let_it_be(:group) { create(:group) }

    context 'when user is not an enterprise user' do
      before do
        user.user_detail.enterprise_group = nil
      end

      it 'returns false' do
        expect(user.enterprise_user_of_group?(group)).to eq false
      end
    end

    context 'when user is an enterprise user of the group' do
      before do
        user.user_detail.enterprise_group = group
      end

      it 'returns true' do
        expect(user.enterprise_user_of_group?(group)).to eq true
      end
    end

    context 'when user is an enterprise user of another group' do
      before do
        user.user_detail.enterprise_group = create(:group)
      end

      it 'returns false' do
        expect(user.enterprise_user_of_group?(group)).to eq false
      end
    end
  end

  describe '#enterprise_user?' do
    let_it_be(:user) { create(:user) }

    context 'when user is not an enterprise user' do
      before do
        user.user_detail.update!(enterprise_group: nil)
      end

      it 'returns false' do
        expect(user.enterprise_user?).to eq false
      end
    end

    context 'when user is an enterprise user' do
      let_it_be(:group) { create(:group) }

      before do
        user.user_detail.update!(enterprise_group: group)
      end

      it 'returns true' do
        expect(user.enterprise_user?).to eq true
      end

      context 'when the group is deleted' do
        before do
          group.destroy!
        end

        it 'returns false' do
          expect(user.reload.enterprise_user?).to eq false
        end
      end
    end
  end

  describe '#password_based_login_forbidden?' do
    context 'when user is provisioned by group' do
      before do
        user.user_detail.provisioned_by_group = build(:group)
      end

      it 'is true' do
        expect(user.password_based_login_forbidden?).to eq true
      end

      context 'with feature flag switched off' do
        before do
          stub_feature_flags(block_password_auth_for_saml_users: false)
        end

        it 'is false' do
          expect(user.password_based_login_forbidden?).to eq false
        end
      end
    end

    context 'when user is not provisioned by group' do
      it 'is false' do
        expect(user.password_based_login_forbidden?).to eq false
      end

      context 'with feature flag switched off' do
        before do
          stub_feature_flags(block_password_auth_for_saml_users: false)
        end

        it 'is false' do
          expect(user.password_based_login_forbidden?).to eq false
        end
      end
    end
  end

  describe '#using_license_seat?' do
    let(:user) { create(:user) }

    context 'when user is inactive' do
      before do
        user.block
      end

      it 'returns false' do
        expect(user.using_license_seat?).to eq false
      end
    end

    context 'when user is active' do
      context 'when user is internal' do
        where(:internal_user_type) do
          described_class::INTERNAL_USER_TYPES
        end

        with_them do
          context 'when user has internal user type' do
            let(:user) { create(:user, user_type: internal_user_type) }

            it 'returns false' do
              expect(user.using_license_seat?).to eq false
            end
          end
        end
      end

      context 'when user is not internal' do
        context 'when license is nil (core/free/default)' do
          before do
            allow(License).to receive(:current).and_return(nil)
          end

          it 'returns false if license is nil (core/free/default)' do
            expect(user.using_license_seat?).to eq false
          end
        end

        context 'user is guest' do
          let(:project_guest_user) { create(:project_member, :guest).user }

          it 'returns false if license is ultimate' do
            create(:license, plan: License::ULTIMATE_PLAN)

            expect(project_guest_user.using_license_seat?).to eq false
          end

          it 'returns true if license is not ultimate and not nil' do
            create(:license, plan: License::STARTER_PLAN)

            expect(project_guest_user.using_license_seat?).to eq true
          end
        end

        context 'user is admin without projects' do
          let(:user) { create(:user, admin: true) }

          it 'returns false if license is ultimate' do
            create(:license, plan: License::ULTIMATE_PLAN)

            expect(user.using_license_seat?).to eq false
          end

          it 'returns true if license is not ultimate and not nil' do
            create(:license, plan: License::STARTER_PLAN)

            expect(user.using_license_seat?).to eq true
          end
        end

        context 'when the user is a service account' do
          let(:user) { create(:user, :service_account) }

          it 'returns false' do
            expect(user.using_license_seat?).to eq(false)
          end
        end
      end
    end
  end

  describe '#using_gitlab_com_seat?' do
    let(:user) { create(:user) }
    let(:namespace) { create(:group) }

    subject { user.using_gitlab_com_seat?(namespace) }

    context 'when Gitlab.com? is false' do
      before do
        allow(Gitlab).to receive(:com?).and_return(false)
      end

      it { is_expected.to be_falsey }
    end

    context 'when user is not active' do
      let(:user) { create(:user, :blocked) }

      it { is_expected.to be_falsey }
    end

    context 'when SaaS', :saas do
      context 'when namespace is nil' do
        let(:namespace) { nil }

        it { is_expected.to be_falsey }
      end

      context 'when namespace is on a free plan' do
        it { is_expected.to be_falsey }
      end

      context 'when namespace is on a ultimate plan' do
        before do
          create(:gitlab_subscription, namespace: namespace.root_ancestor, hosted_plan: create(:ultimate_plan))
        end

        context 'user is a guest' do
          before do
            namespace.add_guest(user)
          end

          it { is_expected.to be_falsey }
        end

        context 'user is not a guest' do
          before do
            namespace.add_developer(user)
          end

          it { is_expected.to be_truthy }
        end

        context 'when user is within project' do
          let(:group) { create(:group) }
          let(:namespace) { create(:project, namespace: group) }

          before do
            namespace.add_developer(user)
          end

          it { is_expected.to be_truthy }
        end

        context 'when user is within subgroup' do
          let(:group) { create(:group) }
          let(:namespace) { create(:group, parent: group) }

          before do
            namespace.add_developer(user)
          end

          it { is_expected.to be_truthy }
        end
      end

      context 'when namespace is on a plan that is not free or ultimate' do
        before do
          create(:gitlab_subscription, namespace: namespace, hosted_plan: create(:premium_plan))
        end

        context 'user is a guest' do
          before do
            namespace.add_guest(user)
          end

          it { is_expected.to be_truthy }
        end

        context 'user is not a guest' do
          before do
            namespace.add_developer(user)
          end

          it { is_expected.to be_truthy }
        end
      end
    end
  end

  describe '#manageable_namespaces_eligible_for_trial', :saas do
    let_it_be(:user) { create :user }
    let_it_be(:non_trialed_group_z) { create :group_with_plan, name: 'Zeta', plan: :free_plan }
    let_it_be(:non_trialed_group_a) { create :group_with_plan, name: 'Alpha', plan: :free_plan }
    let_it_be(:trialed_group) { create :group_with_plan, name: 'Omitted', plan: :free_plan, trial_ends_on: Date.today + 1.day }
    let_it_be(:non_trialed_subgroup) { create :group_with_plan, name: 'Sub-group', plan: :free_plan, parent: non_trialed_group_a }

    subject { user.manageable_namespaces_eligible_for_trial }

    context 'user with no groups' do
      it { is_expected.to eq [] }
    end

    context 'owner of an already-trialed group' do
      before do
        trialed_group.add_owner(user)
      end

      it { is_expected.not_to include trialed_group }
    end

    context 'guest of a non-trialed group' do
      before do
        non_trialed_group_a.add_guest(user)
      end

      it { is_expected.not_to include non_trialed_group_a }
    end

    context 'developer of a non-trialed group' do
      before do
        non_trialed_group_a.add_developer(user)
      end

      it { is_expected.not_to include non_trialed_group_a }
    end

    context 'maintainer of a non-trialed group' do
      before do
        non_trialed_group_a.add_maintainer(user)
      end

      it { is_expected.not_to include non_trialed_group_a }
    end

    context 'owner of 2 non-trialed groups' do
      before do
        non_trialed_group_z.add_owner(user)
        non_trialed_group_a.add_owner(user)
      end

      it { is_expected.to eq [non_trialed_group_a, non_trialed_group_z] }
    end

    context 'owner of a top-level group with a sub-group' do
      before do
        non_trialed_group_a.add_owner(user)
      end

      it { is_expected.to eq [non_trialed_group_a] }
    end
  end

  describe '#authorized_groups' do
    let_it_be(:user) { create(:user) }
    let_it_be(:private_group) { create(:group) }
    let_it_be(:child_group) { create(:group, parent: private_group) }
    let_it_be(:minimal_access_group) { create(:group) }

    let_it_be(:project_group) { create(:group) }
    let_it_be(:project) { create(:project, group: project_group) }

    before do
      private_group.add_member(user, Gitlab::Access::MAINTAINER)
      project.add_maintainer(user)
      create(:group_member, :minimal_access, user: user, source: minimal_access_group)
    end

    subject { user.authorized_groups }

    context 'with minimal access role feature unavailable' do
      it { is_expected.to contain_exactly private_group, project_group }
    end

    context 'with minimal access feature available' do
      before do
        stub_licensed_features(minimal_access_role: true)
      end

      context 'feature turned on for all groups' do
        before do
          allow(Gitlab::CurrentSettings)
            .to receive(:should_check_namespace_plan?)
                  .and_return(false)
        end

        it { is_expected.to contain_exactly private_group, project_group, minimal_access_group }

        it 'ignores groups with minimal access if with_minimal_access=false' do
          expect(user.authorized_groups(with_minimal_access: false)).to contain_exactly(private_group, project_group)
        end
      end

      context 'feature available for specific groups only', :saas do
        before do
          allow(Gitlab::CurrentSettings)
            .to receive(:should_check_namespace_plan?)
                  .and_return(true)
          create(:gitlab_subscription, :ultimate, namespace: minimal_access_group)
          create(:group_member, :minimal_access, user: user, source: create(:group))
        end

        it { is_expected.to contain_exactly private_group, project_group, minimal_access_group }
      end
    end
  end

  describe '#active_for_authentication?' do
    subject { user.active_for_authentication? }

    let(:user) { create(:user) }

    context 'based on user type' do
      using RSpec::Parameterized::TableSyntax

      where(:user_type, :expected_result) do
        'service_user'      | true
        'visual_review_bot' | false
      end

      with_them do
        before do
          user.update!(user_type: user_type)
        end

        it { is_expected.to be expected_result }
      end
    end
  end

  context 'zoekt namespaces', feature_category: :global_search do
    let_it_be(:indexed_parent_namespace) { create(:group) }
    let_it_be(:unindexed_namespace) { create(:namespace) }
    let_it_be(:shard) { Zoekt::Shard.create!(index_base_url: 'http://example.com:1234/', search_base_url: 'http://example.com:4567/') }
    let_it_be(:zoekt_indexed_namespace) { Zoekt::IndexedNamespace.create!(shard: shard, namespace: indexed_parent_namespace) }

    let(:user) { create(:user, namespace: create(:user_namespace)) }

    describe '#zoekt_indexed_namespaces' do
      it 'returns zoekt indexed namespaces for user' do
        indexed_parent_namespace.add_maintainer(user)
        expect(user.zoekt_indexed_namespaces).to match_array([zoekt_indexed_namespace])
      end

      it 'returns empty array if there are user is not have access of reporter or above' do
        expect(user.zoekt_indexed_namespaces).to match_array([])
      end
    end

    describe '#has_zoekt_indexed_namespace?' do
      it 'returns true if there are zoekt_indexed_namespaces' do
        allow(user).to receive(:zoekt_indexed_namespaces).and_return([zoekt_indexed_namespace])
        expect(user).to be_has_zoekt_indexed_namespace

        allow(user).to receive(:zoekt_indexed_namespaces).and_return([])
        expect(user).not_to be_has_zoekt_indexed_namespace
      end
    end
  end

  context 'paid namespaces', :saas do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:ultimate_group) { create(:group_with_plan, plan: :ultimate_plan) }
    let_it_be(:bronze_group) { create(:group_with_plan, plan: :bronze_plan) }
    let_it_be(:free_group) { create(:group_with_plan, plan: :free_plan) }
    let_it_be(:group_without_plan) { create(:group) }

    let(:user) { create(:user, namespace: create(:user_namespace)) }

    describe '#has_paid_namespace?' do
      context 'when the user has Reporter or higher on at least one paid group' do
        it 'returns true' do
          ultimate_group.add_reporter(user)
          bronze_group.add_guest(user)

          expect(user.has_paid_namespace?).to eq(true)
        end
      end

      context 'when the user is only a Guest on paid groups' do
        it 'returns false' do
          ultimate_group.add_guest(user)
          bronze_group.add_guest(user)
          free_group.add_owner(user)

          expect(user.has_paid_namespace?).to eq(false)
        end
      end

      context 'when the user is not a member of any groups with plans' do
        it 'returns false' do
          group_without_plan.add_owner(user)

          expect(user.has_paid_namespace?).to eq(false)
        end
      end

      context 'when passed a subset of plans' do
        it 'returns true', :aggregate_failures do
          bronze_group.add_reporter(user)

          expect(user.has_paid_namespace?(plans: [::Plan::BRONZE])).to eq(true)
          expect(user.has_paid_namespace?(plans: [::Plan::ULTIMATE])).to eq(false)
        end
      end

      context 'when passed a non-paid plan' do
        it 'returns false' do
          free_group.add_owner(user)

          expect(user.has_paid_namespace?(plans: [::Plan::ULTIMATE, ::Plan::FREE])).to eq(false)
        end
      end

      context 'when passed exclude_trials: true' do
        let_it_be(:trial_group) { create(:group_with_plan, plan: :ultimate_plan, trial_ends_on: 1.day.from_now) }

        it 'returns false' do
          trial_group.add_owner(user)

          expect(user.has_paid_namespace?(exclude_trials: true)).to eq(false)
        end
      end
    end

    context 'when passed a plan' do
      it 'calculates association for that plan' do
        bronze_group.add_reporter(user)

        expect(user.has_paid_namespace?(plans: [::Plan::BRONZE])).to eq(true)
        expect(user.has_paid_namespace?(plans: [::Plan::ULTIMATE])).to eq(false)
      end

      it 'calculates association to multiple plans' do
        free_group.add_owner(user)

        expect(user.has_paid_namespace?(plans: [::Plan::ULTIMATE, ::Plan::FREE])).to eq(false)
      end
    end

    describe '#owns_paid_namespace?', :saas do
      context 'when the user is an owner of at least one paid group' do
        it 'returns true' do
          ultimate_group.add_owner(user)
          bronze_group.add_owner(user)

          expect(user.owns_paid_namespace?).to eq(true)
        end
      end

      context 'when the user is only a Maintainer on paid groups' do
        it 'returns false' do
          ultimate_group.add_maintainer(user)
          bronze_group.add_maintainer(user)
          free_group.add_owner(user)

          expect(user.owns_paid_namespace?).to eq(false)
        end
      end

      context 'when the user is not a member of any groups with plans' do
        it 'returns false' do
          group_without_plan.add_owner(user)

          expect(user.owns_paid_namespace?).to eq(false)
        end
      end
    end
  end

  describe '#gitlab_employee?' do
    using RSpec::Parameterized::TableSyntax

    subject { user.gitlab_employee? }

    let_it_be(:gitlab_group) { create(:group, name: 'gitlab-com') }
    let_it_be(:random_group) { create(:group, name: 'random-group') }

    context 'based on group membership' do
      before do
        allow(Gitlab).to receive(:com?).and_return(is_com)
      end

      context 'when user belongs to gitlab-com group' do
        where(:is_com, :expected_result) do
          true  | true
          false | false
        end

        with_them do
          let(:user) { create(:user) }

          before do
            gitlab_group.add_member(user, Gitlab::Access::DEVELOPER)
          end

          it { is_expected.to be expected_result }
        end
      end

      context 'when user does not belongs to gitlab-com group' do
        where(:is_com, :expected_result) do
          true  | false
          false | false
        end

        with_them do
          let(:user) { create(:user) }

          before do
            random_group.add_member(user, Gitlab::Access::DEVELOPER)
          end

          it { is_expected.to be expected_result }
        end
      end
    end

    context 'based on user type' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
        gitlab_group.add_member(user, Gitlab::Access::DEVELOPER)
      end

      context 'when user is a bot' do
        let(:user) { create(:user, user_type: :alert_bot) }

        it { is_expected.to be false }
      end

      context 'when user is ghost' do
        let(:user) { create(:user, :ghost) }

        it { is_expected.to be false }
      end
    end
  end

  describe '#gitlab_bot?' do
    subject { user.gitlab_bot? }

    let_it_be(:gitlab_group) { create(:group, name: 'gitlab-com') }
    let_it_be(:random_group) { create(:group, name: 'random-group') }

    context 'based on group membership' do
      context 'when user belongs to gitlab-com group' do
        let(:user) { create(:user, user_type: :alert_bot) }

        before do
          allow(Gitlab).to receive(:com?).and_return(true)
          gitlab_group.add_member(user, Gitlab::Access::DEVELOPER)
        end

        it { is_expected.to be true }
      end

      context 'when user does not belongs to gitlab-com group' do
        let(:user) { create(:user, user_type: :alert_bot) }

        before do
          allow(Gitlab).to receive(:com?).and_return(true)
          random_group.add_member(user, Gitlab::Access::DEVELOPER)
        end

        it { is_expected.to be false }
      end
    end

    context 'based on user type' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
        gitlab_group.add_member(user, Gitlab::Access::DEVELOPER)
      end

      context 'when user is a bot' do
        let(:user) { create(:user, user_type: :alert_bot) }

        it { is_expected.to be true }
      end

      context 'when user is a human' do
        let(:user) { create(:user, user_type: :human) }

        it { is_expected.to be false }
      end

      context 'when user is ghost' do
        let(:user) { create(:user, :ghost) }

        it { is_expected.to be false }
      end
    end
  end

  describe '#gitlab_service_user?' do
    subject { user.gitlab_service_user? }

    let_it_be(:gitlab_group) { create(:group, name: 'gitlab-com') }
    let_it_be(:random_group) { create(:group, name: 'random-group') }

    context 'based on group membership' do
      context 'when user belongs to gitlab-com group' do
        let(:user) { create(:user, user_type: :service_user) }

        before do
          allow(Gitlab).to receive(:com?).and_return(true)
          gitlab_group.add_member(user, Gitlab::Access::DEVELOPER)
        end

        it { is_expected.to be true }
      end

      context 'when user does not belong to gitlab-com group' do
        let(:user) { create(:user, user_type: :service_user) }

        before do
          allow(Gitlab).to receive(:com?).and_return(true)
          random_group.add_member(user, Gitlab::Access::DEVELOPER)
        end

        it { is_expected.to be false }
      end
    end

    context 'based on user type' do
      using RSpec::Parameterized::TableSyntax

      where(:is_com, :user_type, :answer) do
        true  | :service_user     | true
        true  | :alert_bot        | false
        true  | :human            | false
        true  | :ghost            | false
        false | :service_user     | false
        false | :alert_bot        | false
        false | :human            | false
        false | :ghost            | false
      end

      with_them do
        before do
          allow(Gitlab).to receive(:com?).and_return(is_com)
        end

        let(:user) do
          user = create(:user, user_type: user_type)
          gitlab_group.add_member(user, Gitlab::Access::DEVELOPER)
          user
        end

        it "returns if the user is a GitLab-owned service user" do
          expect(subject).to be answer
        end
      end
    end
  end

  describe '#security_dashboard' do
    let(:user) { create(:user) }

    subject(:security_dashboard) { user.security_dashboard }

    it 'returns an instance of InstanceSecurityDashboard for the user' do
      expect(security_dashboard).to be_a(InstanceSecurityDashboard)
    end
  end

  describe '#find_or_init_board_epic_preference' do
    let_it_be(:user) { create(:user) }
    let_it_be(:board) { create(:board) }
    let_it_be(:epic) { create(:epic) }

    subject(:preference) { user.find_or_init_board_epic_preference(board_id: board.id, epic_id: epic.id) }

    it 'returns new board epic user preference' do
      expect(preference.persisted?).to be_falsey
      expect(preference.user).to eq(user)
    end

    context 'when preference already exists' do
      let_it_be(:epic_user_preference) { create(:epic_user_preference, board: board, epic: epic, user: user) }

      it 'returns the existing board' do
        expect(preference.persisted?).to be_truthy
        expect(preference).to eq(epic_user_preference)
      end
    end
  end

  describe '#can_remove_self?' do
    let(:user) { create(:user) }

    subject { user.can_remove_self? }

    context 'not on GitLab.com' do
      context 'when the password is not automatically set' do
        it { is_expected.to eq true }
      end

      context 'when the password is automatically set' do
        before do
          user.password_automatically_set = true
        end

        it { is_expected.to eq true }
      end
    end

    context 'on GitLab.com' do
      before do
        allow(::Gitlab).to receive(:com?).and_return(true)
      end

      context 'when the password is not automatically set' do
        it { is_expected.to eq true }
      end

      context 'when the password is automatically set' do
        before do
          user.password_automatically_set = true
        end

        it { is_expected.to eq false }
      end
    end
  end

  describe '#has_required_credit_card_to_run_pipelines?' do
    let_it_be(:project) { create(:project) }

    subject { user.has_required_credit_card_to_run_pipelines?(project) }

    using RSpec::Parameterized::TableSyntax

    where(:saas, :cc_present, :shared_runners, :addon_mins, :plan, :feature_flags, :days_from_release, :result, :description) do
      # self-hosted
      nil   | false | :enabled | 0 | :paid  | %i[free trial]           | 0  | true  | 'self-hosted paid plan'
      nil   | false | :enabled | 0 | :trial | %i[free trial]           | 0  | true  | 'self-hosted missing CC on trial plan'

      # saas
      :saas | false | :enabled | 0 | :paid  | %i[free trial old_users] | 0  | true  | 'missing CC on paid plan'

      :saas | false | :enabled | 0 | :free  | %i[free trial]           | 0  | false | 'missing CC on free plan'
      :saas | false | nil      | 0 | :free  | %i[free trial]           | 0  | true  | 'missing CC on free plan and shared runners disabled'
      :saas | false | :enabled | 0 | :free  | %i[free trial]           | -1 | true  | 'missing CC on free plan but old user'
      :saas | false | :enabled | 0 | :free  | %i[free trial old_users] | -1 | false | 'missing CC on free plan but old user and FF enabled'
      :saas | false | nil      | 0 | :free  | %i[free trial old_users] | -1 | true  | 'missing CC on free plan but old user and FF enabled and shared runners disabled'
      :saas | true  | :enabled | 0 | :free  | %i[free trial]           | 0  | true  | 'present CC on free plan'
      :saas | false | :enabled | 0 | :free  | %i[]                     | 0  | true  | 'missing CC on free plan - FF off'

      :saas | false | :enabled | 0 | :trial | %i[free trial]           | 0  | false | 'missing CC on trial plan'
      :saas | false | nil      | 0 | :trial | %i[free trial]           | 0  | true  | 'missing CC on trial plan and shared runners disabled'
      :saas | false | :enabled | 0 | :trial | %i[free trial]           | -1 | true  | 'missing CC on trial plan but old user'
      :saas | false | :enabled | 0 | :trial | %i[free trial old_users] | -1 | false | 'missing CC on trial plan but old user and FF enabled'
      :saas | false | nil      | 0 | :trial | %i[free trial old_users] | -1 | true  | 'missing CC on trial plan but old user and FF enabled and shared runners disabled'
      :saas | false | :enabled | 0 | :trial | %i[]                     | 0  | true  | 'missing CC on trial plan - FF off'
      :saas | true  | :enabled | 0 | :trial | %i[free trial]           | 0  | true  | 'present CC on trial plan'

      :saas | false | :enabled | 100 | :free  | %i[free]               | 0  | true  | 'missing CC on free plan with purchased minutes'
      :saas | false | :enabled | 100 | :trial | %i[trial]              | 0  | true  | 'missing CC on trial plan with purchased minutes'
    end

    let(:shared_runners_enabled) { shared_runners == :enabled }

    with_them do
      before do
        allow(::Gitlab).to receive(:com?).and_return(saas == :saas)
        user.created_at = ::Users::CreditCardValidation::RELEASE_DAY + days_from_release.days
        allow(user).to receive(:credit_card_validated_at).and_return(Time.current) if cc_present
        allow(project.namespace).to receive(:free_plan?).and_return(plan == :free)
        allow(project.namespace).to receive(:trial?).and_return(plan == :trial)
        project.namespace.update!(extra_shared_runners_minutes_limit: addon_mins)
        project.namespace.clear_memoization(:ci_minutes_usage)
        project.update!(shared_runners_enabled: shared_runners_enabled)

        stub_feature_flags(
          ci_require_credit_card_on_free_plan: feature_flags.include?(:free),
          ci_require_credit_card_on_trial_plan: feature_flags.include?(:trial),
          ci_require_credit_card_for_old_users: feature_flags.include?(:old_users))
      end

      it description do
        expect(subject).to eq(result)
      end
    end
  end

  describe '#has_required_credit_card_to_enable_shared_runners?' do
    let_it_be(:project) { create(:project) }

    subject { user.has_required_credit_card_to_enable_shared_runners?(project) }

    using RSpec::Parameterized::TableSyntax

    where(:saas, :cc_present, :addon_mins, :plan, :feature_flags, :days_from_release, :result, :description) do
      # self-hosted
      nil   | false | 0 | :paid  | %i[free trial]           | 0  | true  | 'self-hosted paid plan'
      nil   | false | 0 | :trial | %i[free trial]           | 0  | true  | 'self-hosted missing CC on trial plan'

      # saas
      :saas | false | 0 | :paid  | %i[free trial old_users] | 0  | true  | 'missing CC on paid plan'

      :saas | false | 0 | :free  | %i[free trial]           | 0  | false | 'missing CC on free plan'
      :saas | false | 0 | :free  | %i[free trial]           | -1 | true  | 'missing CC on free plan but old user'
      :saas | false | 0 | :free  | %i[free trial old_users] | -1 | false | 'missing CC on free plan but old user and FF enabled'
      :saas | true  | 0 | :free  | %i[free trial]           | 0  | true  | 'present CC on free plan'
      :saas | false | 0 | :free  | %i[]                     | 0  | true  | 'missing CC on free plan - FF off'

      :saas | false | 0 | :trial | %i[free trial]           | 0  | false | 'missing CC on trial plan'
      :saas | false | 0 | :trial | %i[free trial]           | -1 | true  | 'missing CC on trial plan but old user'
      :saas | false | 0 | :trial | %i[free trial old_users] | -1 | false | 'missing CC on trial plan but old user and FF enabled'
      :saas | false | 0 | :trial | %i[]                     | 0  | true  | 'missing CC on trial plan - FF off'
      :saas | true  | 0 | :trial | %i[free trial]           | 0  | true  | 'present CC on trial plan'

      :saas | false | 100 | :free  | %i[free]               | 0  | true  | 'missing CC on free plan with purchased minutes'
      :saas | false | 100 | :trial | %i[trial]              | 0  | true  | 'missing CC on trial plan with purchased minutes'
    end

    with_them do
      before do
        allow(::Gitlab).to receive(:com?).and_return(saas == :saas)
        user.created_at = ::Users::CreditCardValidation::RELEASE_DAY + days_from_release.days
        allow(user).to receive(:credit_card_validated_at).and_return(Time.current) if cc_present
        allow(project.namespace).to receive(:free_plan?).and_return(plan == :free)
        allow(project.namespace).to receive(:trial?).and_return(plan == :trial)
        project.namespace.update!(extra_shared_runners_minutes_limit: addon_mins)
        project.namespace.clear_memoization(:ci_minutes_usage)
        stub_feature_flags(
          ci_require_credit_card_on_free_plan: feature_flags.include?(:free),
          ci_require_credit_card_on_trial_plan: feature_flags.include?(:trial),
          ci_require_credit_card_for_old_users: feature_flags.include?(:old_users))
      end

      it description do
        expect(subject).to eq(result)
      end
    end
  end

  describe "#owns_group_without_trial" do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }

    subject { user.owns_group_without_trial? }

    it 'returns true if owns a group' do
      group.add_owner(user)

      is_expected.to be(true)
    end

    it 'returns false if is a member group' do
      group.add_maintainer(user)

      is_expected.to be(false)
    end

    it 'returns false if is not a member of any group' do
      is_expected.to be(false)
    end

    it 'returns false if owns a group with a plan on a trial with an end date', :saas do
      group_with_plan = create(:group_with_plan, name: 'trial group', plan: :premium_plan, trial_ends_on: 1.year.from_now)
      group_with_plan.add_owner(user)

      is_expected.to be(false)
    end
  end

  describe '.oncall_schedules' do
    let_it_be(:user) { create(:user) }
    let_it_be(:participant, reload: true) { create(:incident_management_oncall_participant, user: user) }
    let_it_be(:schedule, reload: true) { participant.rotation.schedule }

    it 'excludes removed participants' do
      participant.update!(is_removed: true)

      expect(user.oncall_schedules).to be_empty
    end

    it 'excludes duplicates' do
      create(:incident_management_oncall_rotation, schedule: schedule) do |rotation|
        create(:incident_management_oncall_participant, user: user, rotation: rotation)
      end

      expect(user.oncall_schedules).to contain_exactly(schedule)
    end
  end

  describe '.escalation_policies' do
    let_it_be(:rule, reload: true) { create(:incident_management_escalation_rule, :with_user) }
    let_it_be(:policy, reload: true) { rule.policy }
    let_it_be(:user) { rule.user }

    it 'excludes removed rules' do
      rule.update!(is_removed: true)

      expect(user.escalation_policies).to be_empty
    end

    it 'excludes duplicates' do
      create(:incident_management_escalation_rule, :with_user, :resolved, policy: policy, user: user)

      expect(user.escalation_policies).to contain_exactly(policy)
    end
  end

  describe '.user_cap_reached?' do
    using RSpec::Parameterized::TableSyntax

    subject { described_class.user_cap_reached? }

    where(:billable_count, :user_cap_max, :result) do
      2 | nil | false
      2 | 5   | false
      5 | 5   | true
      8 | 5   | true
    end

    with_them do
      before do
        allow(described_class).to receive_message_chain(:billable, :limit).and_return(Array.new(billable_count, instance_double('User')))
        allow(Gitlab::CurrentSettings).to receive(:new_user_signups_cap).and_return(user_cap_max)
      end

      it { is_expected.to eq(result) }
    end
  end

  describe '.user_cap_max' do
    it 'is equal to new_user_signups_cap setting' do
      cap = 10
      stub_application_setting(new_user_signups_cap: cap)

      expect(described_class.user_cap_max).to eq(cap)
    end
  end

  describe '#blocked_auto_created_oauth_ldap_user?' do
    include LdapHelpers

    before do
      stub_ldap_setting(enabled: true)
    end

    context 'when the auto-creation of an omniauth user is blocked' do
      before do
        stub_omniauth_setting(block_auto_created_users: true)
      end

      context 'when the user is an omniauth user' do
        it 'is true' do
          omniauth_user = create(:omniauth_user)

          expect(omniauth_user.blocked_auto_created_oauth_ldap_user?).to be_truthy
        end
      end

      context 'when the user is not an omniauth user' do
        it 'is false' do
          user = build(:user)

          expect(user.blocked_auto_created_oauth_ldap_user?).to be_falsey
        end
      end

      context 'when the config for auto-creation of LDAP user is set' do
        let(:ldap_user) { create(:omniauth_user, :ldap) }
        let(:ldap_auto_create_blocked) { true }

        before do
          stub_ldap_config(block_auto_created_users: ldap_auto_create_blocked)
        end

        subject(:blocked_user?) { ldap_user.blocked_auto_created_oauth_ldap_user? }

        context 'when it blocks the creation of a LDAP user' do
          it { is_expected.to be_truthy }

          context 'when no provider is linked to the user' do
            let(:ldap_user) { create(:user) }

            it { is_expected.to be_falsey }
          end
        end

        context 'when it does not block the creation of a LDAP user' do
          let(:ldap_auto_create_blocked) { false }

          it { is_expected.to be_falsey }
        end

        context 'when LDAP is disabled' do
          before do
            stub_ldap_setting(enabled: false)
          end

          it { is_expected.to be_falsey }
        end
      end
    end
  end

  describe '#custom_permission_for?', :request_store do
    let_it_be(:project) { create(:project, :in_group) }
    let_it_be(:group) { project.group }
    let_it_be(:user) { create(:user) }

    before do
      stub_licensed_features(custom_roles: true)
    end

    context 'when membership is for a group' do
      before_all do
        group_member = create(:group_member, :guest, user: user, source: group)
        create(
          :member_role,
          :guest,
          admin_vulnerability: false,
          read_code: false,
          read_vulnerability: true,
          members: [group_member],
          namespace: group
        )
      end

      context 'when custom role present for group membership' do
        it 'returns custom role information on the group' do
          expect(user.custom_permission_for?(group, :read_vulnerability)).to be true
          expect(user.custom_permission_for?(group, :admin_vulnerability)).to be false
          expect(user.custom_permission_for?(group, :read_code)).to be false
        end

        it 'returns inherited custom role information on the projects within the group' do
          expect(user.custom_permission_for?(project, :read_vulnerability)).to be true
          expect(user.custom_permission_for?(project, :admin_vulnerability)).to be false
          expect(user.custom_permission_for?(project, :read_code)).to be false
        end

        it 'does not perform extra queries when asked for groups have already been preloaded' do
          user.custom_permission_for?(group, :read_vulnerability)
          expect { user.custom_permission_for?(group, :read_vulnerability) }.not_to exceed_query_limit(0)
        end
      end
    end

    context 'when custom role present for project membership' do
      before_all do
        project_member = create(:project_member, :guest, user: user, source: project)
        create(
          :member_role,
          :guest,
          admin_vulnerability: false,
          read_code: true,
          read_vulnerability: false,
          members: [project_member],
          namespace: project.group
        )
      end

      context 'when read_code present in preloaded custom roles' do
        it 'returns custom role information on the the project' do
          expect(user.custom_permission_for?(project, :read_vulnerability)).to be false
          expect(user.custom_permission_for?(project, :admin_vulnerability)).to be false
          expect(user.custom_permission_for?(project, :read_code)).to be true
        end

        it "returns false for all custom permissions on the project's parent group" do
          expect(user.custom_permission_for?(group, :read_vulnerability)).to be false
          expect(user.custom_permission_for?(group, :admin_vulnerability)).to be false
          expect(user.custom_permission_for?(group, :read_code)).to be false
        end

        it 'does not perform extra queries when asked for projects have already been preloaded' do
          user.custom_permission_for?(project, :read_code)
          expect { user.custom_permission_for?(project, :read_code) }.not_to exceed_query_limit(0)
        end
      end
    end
  end

  describe '#can_group_owner_disable_two_factor?' do
    let_it_be(:group) { create(:group) }
    let_it_be(:owner) { create(:user) }

    context 'when current_user is a group owner' do
      before do
        group.add_owner(owner)
      end

      context 'when user is provisioned by group' do
        let_it_be(:user) { create(:user, :two_factor, provisioned_by_group_id: group.id) }

        context 'when group is root group' do
          it 'returns true' do
            expect(user.can_group_owner_disable_two_factor?(group, owner)).to eq true
          end
        end

        context 'when group is not root group' do
          let(:parent) { build(:group) }

          before do
            group.parent = parent
            parent.add_owner(create(:user))
          end

          it 'returns false' do
            expect(user.can_group_owner_disable_two_factor?(group, owner)).to eq false
          end
        end
      end

      context 'when user is not provisioned by group' do
        let_it_be(:user) { create(:user) }

        it 'returns false' do
          expect(user.can_group_owner_disable_two_factor?(group, owner)).to eq false
        end
      end
    end

    context 'when current_user is not a group owner' do
      let_it_be(:user) { create(:user, :two_factor, provisioned_by_group_id: group.id) }

      before do
        group.add_maintainer(owner)
      end

      it 'returns false' do
        expect(user.can_group_owner_disable_two_factor?(group, owner)).to eq false
      end
    end

    context 'when current_user passed is nil' do
      let_it_be(:user) { create(:user, :two_factor, provisioned_by_group_id: group.id) }

      it 'returns false' do
        expect(user.can_group_owner_disable_two_factor?(group, nil)).to eq false
      end
    end
  end

  describe '#third_party_ai_features_enabled' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:user) { create(:user) }
    let_it_be(:group1, reload: true) { create(:group).tap { |r| r.add_reporter(user) } }
    let_it_be(:group2, reload: true) { create(:group).tap { |r| r.add_reporter(user) } }

    subject { user.third_party_ai_features_enabled? }

    where(:group1_enabled, :group2_enabled, :result) do
      false | false | false
      true  | false | false
      false | true  | false
      true  | true  | true
    end

    with_them do
      before do
        group1.update_attribute(:third_party_ai_features_enabled, group1_enabled)
        group2.update_attribute(:third_party_ai_features_enabled, group2_enabled)
      end

      it { is_expected.to eq result }
    end
  end

  describe '#code_suggestions_disabled_by_group?' do
    let_it_be_with_refind(:user) { create(:user) }
    let_it_be(:allowed_subgroup) do
      allowed_ancestor = create(:group).tap do |record|
        record.update_attribute(:code_suggestions, true)
      end
      create(:group, parent: allowed_ancestor)
    end

    let_it_be(:disallowed_subgroup) do
      disallowed_ancestor = create(:group).tap do |record|
        record.update_attribute(:code_suggestions, false)
      end
      create(:group, parent: disallowed_ancestor)
    end

    subject(:code_suggestions_disabled_by_group?) { user.code_suggestions_disabled_by_group? }

    context 'when code_suggestions setting is false for one group, true for another group' do
      before do
        allowed_subgroup.add_owner(user)
        disallowed_subgroup.add_owner(user)
      end

      it { is_expected.to eq(true) }

      it 'avoids N+1 queries' do
        expect { user.code_suggestions_disabled_by_group? }.to match_query_count(1)
      end
    end

    context 'when code_suggestions setting is true for all groups' do
      before do
        allowed_subgroup.add_owner(user)
      end

      it { is_expected.to eq(false) }
    end
  end

  describe '#preloaded_member_roles_for_projects' do
    let_it_be(:project) { create(:project, :private, :in_group) }
    let_it_be(:user) { create(:user) }
    let_it_be(:project_member) { create(:project_member, :guest, user: user, source: project) }
    let_it_be(:member_role) { create(:member_role, :guest, read_code: true, members: [project_member], namespace: project.group) }

    before do
      stub_licensed_features(custom_roles: true)
    end

    context 'when custom roles are present' do
      context 'when custom role enables read code' do
        it 'returns hash with project ids as keys and read_code in value' do
          preloaded = user.preloaded_member_roles_for_projects([project])

          expect(preloaded).to eq({ project.id => [:read_code] })
        end
      end

      context 'when custom role does not enable read code' do
        let(:user) { create(:user) }
        let(:project_member) { create(:project_member, :guest, user: user, source: project) }
        let(:member_role) { create(:member_role, :guest, read_code: false, members: [project_member], namespace: project.group) }

        it 'returns hash with project ids as keys and empty array as value' do
          preloaded = user.preloaded_member_roles_for_projects([project])

          expect(preloaded).to eq({ project.id => [] })
        end
      end
    end

    context 'when custom roles are not present' do
      it 'returns hash with project ids as keys and empty array as value' do
        project_without_custom_role = create(:project, :in_group)

        preloaded = user.preloaded_member_roles_for_projects([project_without_custom_role])

        expect(preloaded).to eq({ project_without_custom_role.id => [] })
      end
    end

    context 'when custom roles are already preloaded', :request_store do
      it 'does not perform extra queries when asked for projects have already been preloaded' do
        user.preloaded_member_roles_for_projects([project])

        expect { user.custom_permission_for?(project, :read_code) }.not_to exceed_query_limit(0)
      end
    end
  end

  describe '#has_valid_credit_card?' do
    it 'returns true when a credit card validation is present' do
      credit_card_validation = build(:credit_card_validation, credit_card_validated_at: Time.current)
      user = build(:user, credit_card_validation: credit_card_validation)

      expect(user.has_valid_credit_card?).to be_truthy
    end

    it 'returns false when a credit card validation is present, but the credit_card_validated_at attribute is blank' do
      credit_card_validation = build(:credit_card_validation, credit_card_validated_at: nil)
      user = build(:user, credit_card_validation: credit_card_validation)

      expect(user.has_valid_credit_card?).to be_falsey
    end

    it 'returns false when a credit card validation is missing' do
      user = build(:user, credit_card_validation: nil)

      expect(user.has_valid_credit_card?).to be_falsey
    end
  end

  describe "#privatized_by_abuse_automation?" do
    let(:user) { build(:user, private_profile: true, name: 'ghost-123-456') }

    subject(:spam_check) { user.privatized_by_abuse_automation? }

    context 'when the user has a non private profile' do
      it 'returns false' do
        user.private_profile = false

        expect(spam_check).to eq false
      end
    end

    context 'when the user name is not ghost-:id-:id like' do
      it 'returns false' do
        user.name = 'spam-is-not-cool'

        expect(spam_check).to eq false
      end
    end

    context 'when the user name matches ghost-:id-:id' do
      context 'with extra chars at the beginning' do
        it 'returns false' do
          user.name = 'ABCghost-123-456'

          expect(spam_check).to eq false
        end
      end

      context 'with extra chars at the end' do
        it 'returns false' do
          user.name = 'ghost-123-456XYZ'

          expect(spam_check).to eq false
        end
      end

      context 'with extra chars at the beginning and the end' do
        it 'returns false' do
          user.name = 'ABCghost-123-456XYZ'

          expect(spam_check).to eq false
        end
      end
    end

    context 'when the user has a private profile and the format is ghost-:id-:id' do
      it { is_expected.to eq true }
    end
  end

  describe '#activate_based_on_user_cap?' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:user) { create(:user) }

    subject { user.activate_based_on_user_cap? }

    where(:blocked_auto_created_omniauth, :blocked_pending_approval, :user_cap_max_present, :result) do
      true  | true  | true  | false
      false | true  | true  | true
      true  | false | true  | false
      false | false | true  | false
      true  | true  | false | false
      false | true  | false | false
      true  | false | false | false
      false | false | false | false
    end

    with_them do
      before do
        allow(user).to receive(:blocked_auto_created_oauth_ldap_user?).and_return(blocked_auto_created_omniauth)
        allow(user).to receive(:blocked_pending_approval?).and_return(blocked_pending_approval)
        allow(described_class.user_cap_max).to receive(:present?).and_return(user_cap_max_present)
      end

      it { is_expected.to eq(result) }
    end
  end

  describe '.random_password' do
    let(:user) { build(:user) }

    shared_examples_for 'validating with random_password' do
      it 'is valid' do
        user.password = described_class.random_password
        expect(user).to be_valid
      end
    end

    context 'when password_complexity is not available' do
      it 'calls password_length once' do
        expect(described_class).to receive(:password_length).and_call_original

        expect(described_class.random_password.length).to be Devise.password_length.max
      end
    end

    context 'when password_complexity is available' do
      before do
        stub_licensed_features(password_complexity: true)
      end

      context 'without any password complexity polices' do
        it_behaves_like 'validating with random_password'
      end

      context 'when number is required' do
        before do
          stub_application_setting(password_number_required: true)
        end

        it_behaves_like 'validating with random_password'

        it 'is invalid' do
          user.password = 'qwertasdf'
          expect(user).not_to be_valid
        end
      end

      context 'when password complexity is required' do
        before do
          stub_application_setting(password_number_required: true)
          stub_application_setting(password_symbol_required: true)
        end

        it_behaves_like 'validating with random_password'
      end
    end

    context 'when password complexity is available through registration features' do
      before do
        stub_application_setting(usage_ping_features_enabled: true)
      end

      context 'without any password complexity polices' do
        it_behaves_like 'validating with random_password'
      end

      context 'when number is required' do
        before do
          stub_application_setting(password_number_required: true)
        end

        it_behaves_like 'validating with random_password'

        it 'is invalid' do
          user.password = 'qwertasdf'
          expect(user).not_to be_valid
        end

        context 'when password complexity is required' do
          before do
            stub_application_setting(password_symbol_required: true)
          end

          it_behaves_like 'validating with random_password'
        end
      end
    end
  end

  describe '.banned_from_namespace?' do
    let(:user) { build(:user) }
    let(:namespace) { build(:group) }

    subject { user.banned_from_namespace?(namespace) }

    context 'when namespace ban does not exist' do
      it { is_expected.to eq(false) }
    end

    context 'when namespace ban exists' do
      before do
        create(:namespace_ban, namespace: namespace, user: user)
      end

      it { is_expected.to eq(true) }
    end
  end

  it 'includes IdentityVerifiable' do
    expect(described_class).to include_module(IdentityVerifiable)
  end

  it 'includes Elastic::ApplicationVersionedSearch', feature_category: :global_search do
    expect(described_class).to include_module(Elastic::ApplicationVersionedSearch)
  end

  it 'includes Ai::Model' do
    expect(described_class).to include_module(Ai::Model)
  end

  describe 'Elastic::ApplicationVersionedSearch', :elastic, feature_category: :global_search do
    let_it_be_with_reload(:user) { create(:user) }
    let_it_be(:group) { create(:group) }

    before do
      stub_ee_application_setting(elasticsearch_indexing: true)
    end

    context 'on create' do
      it 'always calls track' do
        expect(Elastic::ProcessBookkeepingService).to receive(:track!).once

        create(:user)
      end
    end

    context 'on delete' do
      it 'always calls track' do
        user = create(:user)

        expect(Elastic::ProcessBookkeepingService).to receive(:track!).once

        user.destroy!
      end
    end

    context 'on update' do
      context 'when an elastic field is updated' do
        it 'always calls track' do
          expect(Elastic::ProcessBookkeepingService).to receive(:track!).once

          user.update!(name: 'New Name')
        end
      end

      context 'when a non-elastic field is updated' do
        it 'does not call track' do
          expect(Elastic::ProcessBookkeepingService).not_to receive(:track!)

          user.update!(user_type: 'automation_bot')
        end
      end

      it 'invokes maintain_elasticsearch_update callback' do
        expect(user).to receive(:maintain_elasticsearch_update).once

        user.update!(name: 'New Name')
      end
    end

    context 'when a membership is created' do
      let_it_be(:group) { create(:group) }

      it 'always calls track' do
        expect(Elastic::ProcessBookkeepingService).to receive(:track!).once

        create(:group_member, :developer, source: group, user: user)
      end
    end

    context 'when a membership is deleted' do
      let_it_be(:membership) { create(:group_member, :developer, source: group, user: user) }

      it 'always calls track' do
        expect(Elastic::ProcessBookkeepingService).to receive(:track!).once

        membership.destroy!
      end
    end

    context 'when a membership is updated' do
      let_it_be(:membership) { create(:group_member, :developer, source: group, user: user) }

      it 'does not call track' do
        expect(Elastic::ProcessBookkeepingService).not_to receive(:track!)

        membership.update!(notification_level: 2)
      end
    end
  end

  it 'overrides .use_separate_indices? to true', feature_category: :global_search do
    expect(described_class.use_separate_indices?).to eq(true)
  end

  describe '#use_elasticsearch?', feature_category: :global_search do
    [true, false].each do |matcher|
      describe '#use_elasticsearch?' do
        before do
          stub_ee_application_setting(elasticsearch_search: matcher)
        end

        it 'is equal to elasticsearch_search setting' do
          expect(subject.use_elasticsearch?).to eq(matcher)
        end
      end
    end
  end

  describe '#maintaining_elasticsearch?', :elastic, feature_category: :global_search do
    subject { user.maintaining_elasticsearch? }

    context 'when elasticsearch_indexing is enabled' do
      before do
        stub_ee_application_setting(elasticsearch_indexing: true)
      end

      it { is_expected.to eq(true) }
    end

    context 'when elasticsearch_indexing is disabled' do
      before do
        stub_ee_application_setting(elasticsearch_indexing: false)
      end

      it { is_expected.to eq(false) }
    end
  end

  describe '#delete_async', :saas do
    context 'when target user is the same as deleted_by' do
      let_it_be(:user) { create(:user) }

      subject { user.delete_async(deleted_by: user) }

      before do
        allow(user).to receive(:has_possible_spam_contributions?).and_return(true)
      end

      context 'when user is not a member of a namespace with a paid plan subscription (excluding trials)' do
        it 'schedules the user for deletion with delay' do
          expect(user).to receive(:has_paid_namespace?).with(exclude_trials: true).and_return(false)
          expect(DeleteUserWorker).to receive(:perform_in)
          expect(DeleteUserWorker).not_to receive(:perform_async)

          subject
        end
      end

      context 'when user is a member of a namespace with a paid plan subscription (excluding trials)' do
        it 'schedules user for deletion without delay' do
          expect(user).to receive(:has_paid_namespace?).with(exclude_trials: true).and_return(true)
          expect(DeleteUserWorker).to receive(:perform_async)
          expect(DeleteUserWorker).not_to receive(:perform_in)

          subject
        end
      end
    end
  end

  describe '#lock_access!' do
    let_it_be(:gitlab_admin_bot) { described_class.admin_bot }
    let_it_be_with_reload(:user) { create(:user) }

    subject { user.lock_access! }

    before do
      stub_licensed_features(admin_audit_log: true)
    end

    it 'logs a user_access_locked audit event' do
      expect(::Gitlab::Audit::Auditor).to receive(:audit).with(
        hash_including(
          name: 'user_access_locked',
          author: gitlab_admin_bot,
          scope: user,
          target: user,
          message: 'User access locked'
        )
      ).and_call_original
      expect { subject }.to change { AuditEvent.count }.by(1)
    end

    context 'when reason is known' do
      before do
        allow(user).to receive(:attempts_exceeded?).and_return(true)
      end

      it 'logs a user_access_locked audit event with the correct message' do
        expect(::Gitlab::Audit::Auditor).to receive(:audit).with(
          hash_including(message: 'User access locked - excessive failed login attempts')
        )

        subject
      end

      context 'when reason is passed in as an option' do
        subject { user.lock_access!(reason: 'specified reason') }

        it 'logs a user_access_locked audit event with the correct message' do
          expect(::Gitlab::Audit::Auditor).to receive(:audit).with(
            hash_including(message: 'User access locked - specified reason')
          )

          subject
        end
      end
    end

    context 'when user access is already locked' do
      before do
        user.lock_access!
      end

      it 'does not log an audit event' do
        expect { subject }.not_to change { AuditEvent.count }
      end
    end
  end

  describe '#any_group_with_ai_available?', :saas, :use_clean_rails_redis_caching do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:user) { create(:user) }
    let_it_be_with_reload(:ultimate_group) { create(:group_with_plan, plan: :ultimate_plan) }
    let_it_be_with_reload(:bronze_group) { create(:group_with_plan, plan: :bronze_plan) }
    let_it_be_with_reload(:free_group) { create(:group_with_plan, plan: :free_plan) }
    let_it_be_with_reload(:group_without_plan) { create(:group) }
    let_it_be_with_reload(:trial_group) { create(:group_with_plan, plan: :ultimate_plan, trial_ends_on: 1.day.from_now) }
    let_it_be_with_reload(:ultimate_sub_group) { create(:group, parent: ultimate_group) }
    let_it_be_with_reload(:bronze_sub_group) { create(:group, parent: bronze_group) }

    subject(:group_with_ai_enabled) { user.any_group_with_ai_available? }

    where(:group, :result) do
      ref(:bronze_group)       | false
      ref(:free_group)         | false
      ref(:group_without_plan) | false
      ref(:ultimate_group)     | true
      ref(:trial_group)        | true
    end

    with_them do
      context 'when member of the root group' do
        before do
          group.add_guest(user)
        end

        context 'when ai features are enabled' do
          include_context 'with ai features enabled for group'

          it { is_expected.to eq(result) }

          it 'caches the result' do
            group_with_ai_enabled

            expect(Rails.cache.fetch(['users', user.id, 'group_with_ai_enabled'])).to eq(result)
          end
        end

        context 'when ai features are not enabled' do
          it { is_expected.to eq(false) }
        end
      end
    end

    context 'when member of a sub-group only' do
      include_context 'with ai features enabled for group'

      context 'with eligible group' do
        let(:group) { ultimate_group }

        before do
          ultimate_sub_group.add_guest(user)
        end

        it { is_expected.to eq(true) }
      end

      context 'with not eligible group' do
        let(:group) { bronze_group }

        before do
          bronze_sub_group.add_guest(user)
        end

        it { is_expected.to eq(false) }
      end
    end

    context 'when member of a project only' do
      include_context 'with ai features enabled for group'

      context 'with eligible group' do
        let(:group) { ultimate_group }
        let_it_be(:project) { create(:project, group: ultimate_group) }

        before do
          project.add_guest(user)
        end

        it { is_expected.to eq(true) }
      end

      context 'with not eligible group' do
        let(:group) { bronze_group }
        let_it_be(:project) { create(:project, group: bronze_group) }

        before do
          project.add_guest(user)
        end

        it { is_expected.to eq(false) }
      end
    end
  end

  describe '#unlock_access!' do
    let_it_be_with_reload(:user) { create(:user) }

    subject { user.unlock_access! }

    before do
      stub_licensed_features(admin_audit_log: true)

      user.lock_access!
    end

    shared_examples 'logs a user_access_unlocked audit event with the correct author' do
      it 'logs a user_access_unlocked audit event with the correct author' do
        expect(::Gitlab::Audit::Auditor).to receive(:audit).with(
          hash_including(
            name: 'user_access_unlocked',
            author: expected_author,
            scope: user,
            target: user,
            message: 'User access unlocked'
          )
        ).and_call_original

        expect { subject }.to change { AuditEvent.count }.by(1)
      end
    end

    it_behaves_like 'logs a user_access_unlocked audit event with the correct author' do
      let(:expected_author) { user }
    end

    context 'when unlocked_by is specified' do
      it_behaves_like 'logs a user_access_unlocked audit event with the correct author' do
        let_it_be(:expected_author) { create(:user) }

        subject { user.unlock_access!(unlocked_by: expected_author) }
      end
    end

    context 'when user access is not locked' do
      let_it_be(:active_user) { create(:user) }

      it 'does not log an audit event' do
        expect { active_user.unlock_access! }.not_to change { AuditEvent.count }
      end
    end
  end
end
