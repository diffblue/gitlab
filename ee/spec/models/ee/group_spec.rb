# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Group, feature_category: :subgroups do
  using RSpec::Parameterized::TableSyntax

  let(:group) { create(:group) }

  it { is_expected.to include_module(EE::Group) }
  it { is_expected.to be_kind_of(ReactiveCaching) }

  describe 'associations' do
    it { is_expected.to have_many(:audit_events).dependent(false) }
    # shoulda-matchers attempts to set the association to nil to ensure
    # the presence check works, but since this is a private method that
    # method can't be called with a public_send.
    it { is_expected.to belong_to(:file_template_project).class_name('Project').without_validating_presence }
    it { is_expected.to have_many(:ip_restrictions) }
    it { is_expected.to have_many(:allowed_email_domains) }
    it { is_expected.to have_many(:compliance_management_frameworks) }
    it { is_expected.to have_one(:deletion_schedule) }
    it { is_expected.to have_one(:group_wiki_repository) }
    it { is_expected.to belong_to(:push_rule).inverse_of(:group) }
    it { is_expected.to have_many(:saml_group_links) }
    it { is_expected.to have_many(:epics) }
    it { is_expected.to have_many(:epic_boards).inverse_of(:group) }
    it { is_expected.to have_many(:provisioned_user_details).inverse_of(:provisioned_by_group) }
    it { is_expected.to have_many(:provisioned_users) }
    it { is_expected.to have_one(:group_merge_request_approval_setting) }
    it { is_expected.to have_many(:repository_storage_moves) }
    it { is_expected.to have_many(:iterations) }
    it { is_expected.to have_many(:iterations_cadences) }
    it { is_expected.to have_many(:epic_board_recent_visits).inverse_of(:group) }
    it { is_expected.to have_many(:external_audit_event_destinations) }
    it { is_expected.to have_many(:google_cloud_logging_configurations) }
    it { is_expected.to have_one(:analytics_dashboards_pointer) }
    it { is_expected.to have_one(:analytics_dashboards_configuration_project) }

    it_behaves_like 'model with wiki' do
      let(:container) { create(:group, :nested, :wiki_repo) }
      let(:container_without_wiki) { create(:group, :nested) }
    end
  end

  describe 'scopes' do
    describe '.with_custom_file_templates' do
      let!(:excluded_group) { create(:group) }
      let(:included_group) { create(:group) }
      let(:project) { create(:project, namespace: included_group) }

      before do
        stub_licensed_features(custom_file_templates_for_namespace: true)

        included_group.update!(file_template_project: project)
      end

      subject(:relation) { described_class.with_custom_file_templates }

      it { is_expected.to contain_exactly(included_group) }

      it 'preloads everything needed to show a valid checked_file_template_project' do
        group = relation.first

        expect { group.checked_file_template_project }.not_to exceed_query_limit(0)

        expect(group.checked_file_template_project).to be_present
      end
    end

    describe '.with_saml_provider' do
      subject(:relation) { described_class.with_saml_provider }

      it 'preloads saml_providers' do
        create(:saml_provider, group: group)

        expect(relation.first.association(:saml_provider)).to be_loaded
      end
    end

    describe '.aimed_for_deletion' do
      let!(:date) { 10.days.ago }

      subject(:relation) { described_class.aimed_for_deletion(date) }

      it 'only includes groups that are marked for deletion on or before the specified date' do
        group_not_marked_for_deletion = create(:group)

        group_marked_for_deletion_after_specified_date = create(:group_with_deletion_schedule,
                                                                marked_for_deletion_on: date + 2.days)

        group_marked_for_deletion_before_specified_date = create(:group_with_deletion_schedule,
                                                                 marked_for_deletion_on: date - 2.days)

        group_marked_for_deletion_on_specified_date = create(:group_with_deletion_schedule,
                                                             marked_for_deletion_on: date)

        expect(relation).to include(group_marked_for_deletion_before_specified_date,
                                    group_marked_for_deletion_on_specified_date)
        expect(relation).not_to include(group_marked_for_deletion_after_specified_date,
                                        group_not_marked_for_deletion)
      end
    end

    describe '.for_epics' do
      let_it_be(:epic1) { create(:epic) }
      let_it_be(:epic2) { create(:epic) }

      it 'returns groups only for selected epics' do
        epics = ::Epic.where(id: epic1)
        expect(described_class.for_epics(epics)).to contain_exactly(epic1.group)
      end
    end

    describe '.with_managed_accounts_enabled' do
      subject { described_class.with_managed_accounts_enabled }

      let!(:group_with_with_managed_accounts_enabled) { create(:group_with_managed_accounts) }
      let!(:group_without_managed_accounts_enabled) { create(:group) }

      it 'includes the groups that has managed accounts enabled' do
        expect(subject).to contain_exactly(group_with_with_managed_accounts_enabled)
      end
    end

    describe '.with_no_pat_expiry_policy' do
      subject { described_class.with_no_pat_expiry_policy }

      let!(:group_with_pat_expiry_policy) { create(:group, max_personal_access_token_lifetime: 1) }
      let!(:group_with_no_pat_expiry_policy) { create(:group, max_personal_access_token_lifetime: nil) }

      it 'includes the groups that has no PAT expiry policy set' do
        expect(subject).to contain_exactly(group_with_no_pat_expiry_policy)
      end
    end

    describe '.user_is_member' do
      let_it_be(:user) { create(:user) }
      let_it_be(:not_member_group) { create(:group) }
      let_it_be(:shared_group) { create(:group) }
      let_it_be(:direct_group) { create(:group) }
      let_it_be(:inherited_group) { create(:group, parent: direct_group) }
      let_it_be(:group_link) { create(:group_group_link, shared_group: shared_group, shared_with_group: direct_group) }
      let_it_be(:minimal_access_group) { create(:group) }

      before do
        direct_group.add_guest(user)
        create(:group_member, :minimal_access, user: user, source: minimal_access_group)
      end

      it 'returns only groups where user is direct or indirect member ignoring inheritance and minimal access level' do
        expect(described_class.user_is_member(user)).to match_array([shared_group, direct_group])
      end
    end

    describe '.invited_groups_in_groups_for_hierarchy' do
      let_it_be(:group) { create(:group) }
      let_it_be(:sub_group) { create(:group, parent: group) }
      let_it_be(:ancestor_invited_group) { create(:group) }
      let_it_be(:invited_group) { create(:group, parent: ancestor_invited_group) }
      let_it_be(:invited_guest_group) { create(:group) }
      let_it_be(:sub_invited_group) { create(:group) }
      let_it_be(:internal_invited_group) { create(:group, parent: group) }

      before_all do
        create(:group_group_link)
        create(:group_group_link, { shared_with_group: sub_invited_group, shared_group: sub_group })
        create(:group_group_link, { shared_with_group: invited_group, shared_group: group })
        create(:group_group_link, :guest, { shared_with_group: invited_guest_group, shared_group: group })
        create(:group_group_link, { shared_with_group: internal_invited_group, shared_group: group })
      end

      context 'with guests' do
        it 'includes all groups from group invites' do
          expect(described_class.invited_groups_in_groups_for_hierarchy(group))
            .to match_array([invited_guest_group, invited_group, sub_invited_group, internal_invited_group])
        end
      end

      context 'without guests' do
        it 'includes all groups from group invites' do
          expect(described_class.invited_groups_in_groups_for_hierarchy(group, true))
            .to match_array([invited_group, sub_invited_group, internal_invited_group])
        end
      end
    end

    describe '.invited_groups_in_projects_for_hierarchy' do
      let_it_be(:group) { create(:group) }
      let_it_be(:project) { create(:project, namespace: group) }
      let_it_be(:sub_group_project) { create(:project, namespace: create(:group, parent: group)) }
      let_it_be(:ancestor_invited_group) { create(:group) }
      let_it_be(:invited_group) { create(:group, parent: ancestor_invited_group) }
      let_it_be(:invited_guest_group) { create(:group) }
      let_it_be(:sub_invited_group) { create(:group) }
      let_it_be(:internal_invited_group) { create(:group, parent: group) }

      before_all do
        create(:project_group_link)
        create(:project_group_link, project: project, group: invited_group)
        create(:project_group_link, project: sub_group_project, group: sub_invited_group)
        create(:project_group_link, :guest, project: project, group: invited_guest_group)
        create(:project_group_link, project: project, group: internal_invited_group)
      end

      context 'with guests' do
        it 'includes all groups from group invites' do
          expect(described_class.invited_groups_in_projects_for_hierarchy(group))
            .to match_array([invited_group, sub_invited_group, invited_guest_group, internal_invited_group])
        end
      end

      context 'without guests' do
        it 'includes all groups from group invites' do
          expect(described_class.invited_groups_in_projects_for_hierarchy(group, true))
            .to match_array([invited_group, sub_invited_group, internal_invited_group])
        end
      end
    end

    describe '.with_trial_started_on', :saas do
      let(:ten_days_ago) { 10.days.ago }

      it 'returns correct group' do
        create(:group)

        create(:gitlab_subscription, :active_trial,
               namespace: create(:group),
               trial_starts_on: 1.day.ago)

        create(:gitlab_subscription, :active_trial,
               namespace: group,
               trial_starts_on: ten_days_ago)

        expect(described_class.with_trial_started_on(ten_days_ago)).to match_array([group])
      end
    end
  end

  describe 'validations' do
    context 'max_personal_access_token_lifetime' do
      it { is_expected.to allow_value(1).for(:max_personal_access_token_lifetime) }
      it { is_expected.to allow_value(nil).for(:max_personal_access_token_lifetime) }
      it { is_expected.to allow_value(10).for(:max_personal_access_token_lifetime) }
      it { is_expected.to allow_value(365).for(:max_personal_access_token_lifetime) }
      it { is_expected.not_to allow_value("value").for(:max_personal_access_token_lifetime) }
      it { is_expected.not_to allow_value(2.5).for(:max_personal_access_token_lifetime) }
      it { is_expected.not_to allow_value(-5).for(:max_personal_access_token_lifetime) }
      it { is_expected.not_to allow_value(366).for(:max_personal_access_token_lifetime) }
    end

    context 'validates if custom_project_templates_group_id is allowed' do
      let(:subgroup_1) { create(:group, parent: group) }

      it 'rejects change if the assigned group is not a subgroup' do
        group.custom_project_templates_group_id = create(:group).id

        expect(group).not_to be_valid
        expect(group.errors.messages[:custom_project_templates_group_id]).to match_array(['has to be a subgroup of the group'])
      end

      it 'allows value if the assigned value is from a subgroup' do
        group.custom_project_templates_group_id = subgroup_1.id

        expect(group).to be_valid
      end

      it 'rejects change if the assigned value is from a subgroup\'s descendant group' do
        subgroup_1_1 = create(:group, parent: subgroup_1)
        group.custom_project_templates_group_id = subgroup_1_1.id

        expect(group).not_to be_valid
      end

      it 'allows value when it is blank' do
        subgroup = create(:group, parent: group)
        group.update!(custom_project_templates_group_id: subgroup.id)

        group.custom_project_templates_group_id = ""

        expect(group).to be_valid
      end
    end
  end

  describe 'delegations' do
    it { is_expected.to delegate_method(:code_suggestions).to(:namespace_settings).allow_nil }
    it { is_expected.to delegate_method(:code_suggestions=).to(:namespace_settings).with_arguments(true).allow_nil }
  end

  describe 'states' do
    it { is_expected.to be_ldap_sync_ready }

    context 'after the start transition' do
      it 'sets the last sync timestamp' do
        expect { group.start_ldap_sync }.to change(group, :ldap_sync_last_sync_at)
      end
    end

    context 'after the finish transition' do
      it 'sets the state to started' do
        group.start_ldap_sync

        expect(group).to be_ldap_sync_started

        group.finish_ldap_sync
      end

      it 'sets last update and last successful update to the same timestamp' do
        group.start_ldap_sync

        group.finish_ldap_sync

        expect(group.ldap_sync_last_update_at)
          .to eq(group.ldap_sync_last_successful_update_at)
      end

      it 'clears previous error message on success' do
        group.start_ldap_sync
        group.mark_ldap_sync_as_failed('Error')
        group.start_ldap_sync

        group.finish_ldap_sync

        expect(group.ldap_sync_error).to be_nil
      end
    end

    context 'after the fail transition' do
      it 'sets the state to failed' do
        group.start_ldap_sync

        group.fail_ldap_sync

        expect(group).to be_ldap_sync_failed
      end

      it 'sets last update timestamp but not last successful update timestamp' do
        group.start_ldap_sync

        group.fail_ldap_sync

        expect(group.ldap_sync_last_update_at)
          .not_to eq(group.ldap_sync_last_successful_update_at)
      end
    end
  end

  describe '.groups_user_can' do
    let_it_be(:public_group) { create(:group, :public) }
    let_it_be(:internal_subgroup) { create(:group, :internal, parent: public_group) }
    let_it_be(:private_subgroup_1) { create(:group, :private, parent: internal_subgroup) }
    let_it_be(:private_subgroup_2) { create(:group, :private, parent: private_subgroup_1) }
    let_it_be(:shared_with_group) { create(:group, :private) }

    let(:user) { create(:user) }
    let(:groups) { described_class.where(id: [public_group.id, internal_subgroup.id, private_subgroup_1.id, private_subgroup_2.id]) }
    let(:params) { { same_root: true } }
    let(:shared_group_access) { GroupMember::GUEST }

    before do
      create(:group_group_link, { shared_with_group: shared_with_group,
                                  shared_group: private_subgroup_1,
                                  group_access: shared_group_access })
    end

    subject do
      described_class.groups_user_can(groups, user, action, **params)
    end

    shared_examples 'a filter for permissioned groups' do
      context 'with epics enabled' do
        before do
          stub_licensed_features(epics: true)
        end

        context 'when groups array is empty' do
          let(:groups) { [] }

          it 'does not use filter optimization' do
            expect(Group).not_to receive(:filter_groups_user_can)

            expect(subject).to be_empty
          end
        end

        it 'uses filter optmization to return groups with access' do
          expect(Group).not_to receive(:filter_groups_user_can)

          expect(subject).to match_array(expected_groups)
        end

        context 'when use_traversal_ids is disabled' do
          before do
            stub_feature_flags(use_traversal_ids: false)
          end

          it 'does not use filter optimization' do
            expect(Group).not_to receive(:filter_groups_user_can)
            expect(subject).to match_array(expected_groups)
          end
        end

        context 'when same_root is false' do
          let(:params) { { same_root: false } }

          it 'does not use filter optimization' do
            expect(Group).not_to receive(:filter_groups_user_can)

            expect(subject).to match_array(expected_groups)
          end
        end
      end

      context 'with epics disabled' do
        before do
          stub_licensed_features(epics: false)
        end

        it 'returns an empty list' do
          expect(subject).to be_empty
        end
      end
    end

    context 'for :read_epic permission' do
      let(:action) { :read_epic }

      context 'when user has minimal access to group' do
        before do
          public_group.add_member(user, Gitlab::Access::MINIMAL_ACCESS)
        end

        it_behaves_like 'a filter for permissioned groups' do
          let(:expected_groups) { [public_group, internal_subgroup] }
        end
      end

      context 'when user is a group member' do
        before do
          public_group.add_guest(user)
        end

        it_behaves_like 'a filter for permissioned groups' do
          let(:expected_groups) { [public_group, internal_subgroup, private_subgroup_1, private_subgroup_2] }
        end
      end

      context 'when user is not member of any group' do
        it_behaves_like 'a filter for permissioned groups' do
          let(:user) { create(:user) }
          let(:expected_groups) { [public_group, internal_subgroup] }
        end
      end

      context 'when user has membership from a group share' do
        let_it_be(:user) { create(:user) }

        before do
          shared_with_group.add_guest(user)
        end

        it_behaves_like 'a filter for permissioned groups' do
          let(:expected_groups) { [public_group, internal_subgroup, private_subgroup_1, private_subgroup_2] }
        end
      end

      context 'when user is member of a project in the hierarchy' do
        let_it_be(:private_subgroup_with_project) { create(:group, :private, parent: public_group) }
        let_it_be(:project) { create(:project, group: private_subgroup_with_project) }

        let(:user) { create(:user) }
        let(:groups) { described_class.where(id: [private_subgroup_with_project, public_group.id, internal_subgroup.id, private_subgroup_1.id, private_subgroup_2.id]) }

        before do
          project.add_developer(user)
        end

        it_behaves_like 'a filter for permissioned groups' do
          let(:expected_groups) { [public_group, internal_subgroup, private_subgroup_with_project] }
        end
      end

      context 'when user is member of a child group that has a project' do
        let_it_be(:project) { create(:project, group: private_subgroup_2) }

        before do
          private_subgroup_2.add_guest(user)
        end

        it_behaves_like 'a filter for permissioned groups' do
          let(:expected_groups) { [public_group, internal_subgroup, private_subgroup_1, private_subgroup_2] }
        end
      end
    end

    context 'for :read_confidential_epic permission' do
      let(:action) { :read_confidential_epic }

      context 'when user is guest' do
        before do
          private_subgroup_1.add_guest(user)
        end

        it_behaves_like 'a filter for permissioned groups' do
          let(:expected_groups) { [] }
        end
      end

      context 'when user is reporter' do
        before do
          private_subgroup_1.add_reporter(user)
        end

        it_behaves_like 'a filter for permissioned groups' do
          let(:expected_groups) { [private_subgroup_1, private_subgroup_2] }
        end
      end

      context 'when user is reporter via shared group' do
        let(:shared_group_access) { GroupMember::REPORTER }

        before do
          shared_with_group.add_reporter(user)
        end

        it_behaves_like 'a filter for permissioned groups' do
          let(:expected_groups) { [private_subgroup_1, private_subgroup_2] }
        end
      end

      context 'when user is member of a project in the hierarchy' do
        let_it_be(:private_subgroup_with_project) { create(:group, :private, parent: public_group) }
        let_it_be(:project) { create(:project, group: private_subgroup_with_project) }

        let(:user) { create(:user) }
        let(:groups) { described_class.where(id: [private_subgroup_with_project, public_group.id, internal_subgroup.id, private_subgroup_1.id, private_subgroup_2.id]) }

        before do
          project.add_developer(user)
        end

        it_behaves_like 'a filter for permissioned groups' do
          let(:expected_groups) { [] }
        end
      end
    end

    context 'when action is not allowed to use filtering optmization' do
      let(:action) { :read_nested_project_resources }

      before do
        private_subgroup_1.add_reporter(user)
      end

      it 'returns an empty list' do
        expect(subject).to be_empty
      end
    end

    context 'getting group root ancestor' do
      before do
        public_group.add_reporter(user)
      end

      shared_examples 'group root ancestor' do
        it 'does not exceed SQL queries count' do
          groups = described_class.where(id: private_subgroup_1)
          control_count = ActiveRecord::QueryRecorder.new do
            described_class.groups_user_can(groups, user, :read_epic, **params)
          end.count

          groups = described_class.where(id: [private_subgroup_1, private_subgroup_2])
          expect { described_class.groups_user_can(groups, user, :read_epic, **params) }
            .not_to exceed_query_limit(control_count + extra_query_count)
        end
      end

      context 'when same_root is false' do
        let(:params) { { same_root: false } }

        # extra 6 queries:
        # * getting root_ancestor
        # * getting root ancestor's saml_provider
        # * check if group has projects
        # * max_member_access_for_user_from_shared_groups
        # * max_member_access_for_user
        # * self_and_ancestors_ids
        it_behaves_like 'group root ancestor' do
          let(:extra_query_count) { 6 }
        end
      end

      context 'when same_root is true' do
        let(:params) { { same_root: true } }

        # avoids 2 queries from the list above:
        # * getting root ancestor
        # * getting root ancestor's saml_provider
        it_behaves_like 'group root ancestor' do
          let(:extra_query_count) { 4 }
        end
      end
    end
  end

  describe '.preload_root_saml_providers' do
    let_it_be(:group1) { create(:group, saml_provider: create(:saml_provider)) }
    let_it_be(:group2) { create(:group, saml_provider: create(:saml_provider)) }
    let_it_be(:subgroup1) do
      create(:group, :private, parent: group1).tap do |group|
        group.association(:parent).reset
      end
    end

    let_it_be(:subgroup2) do
      create(:group, :private, parent: group2).tap do |group|
        group.association(:parent).reset
      end
    end

    let(:groups_to_load) { described_class.where(id: [subgroup1.id, subgroup2.id]) }

    it 'sets root_saml_provider for given groups' do
      # Verify that `parent` is not loaded to prevent skipping the query
      # in Namespaces::Traversal::Linear#root_ancestor
      expect(subgroup1.association(:parent)).not_to be_loaded
      expect(subgroup2.association(:parent)).not_to be_loaded

      described_class.preload_root_saml_providers(groups_to_load)

      expect { groups_to_load.map(&:root_saml_provider) }.not_to exceed_query_limit(0)
      expect(subgroup1.root_saml_provider).to eq(group1.saml_provider)
      expect(subgroup2.root_saml_provider).to eq(group2.saml_provider)
    end
  end

  describe '#vulnerabilities' do
    subject { group.vulnerabilities }

    let(:subgroup) { create(:group, parent: group) }
    let(:group_project) { create(:project, namespace: group) }
    let(:subgroup_project) { create(:project, namespace: subgroup) }
    let(:archived_project) { create(:project, :archived, namespace: group) }
    let(:deleted_project) { create(:project, pending_delete: true, namespace: group) }
    let!(:group_vulnerability) { create(:vulnerability, project: group_project) }
    let!(:subgroup_vulnerability) { create(:vulnerability, project: subgroup_project) }
    let!(:archived_vulnerability) { create(:vulnerability, project: archived_project) }
    let!(:deleted_vulnerability) { create(:vulnerability, project: deleted_project) }

    it 'returns vulnerabilities for all non-archived, non-deleted projects in the group and its subgroups' do
      is_expected.to contain_exactly(group_vulnerability, subgroup_vulnerability)
    end
  end

  describe '#vulnerability_reads' do
    subject { group.vulnerability_reads }

    let(:subgroup) { create(:group, parent: group) }
    let(:group_project) { create(:project, namespace: group) }
    let(:subgroup_project) { create(:project, namespace: subgroup) }
    let(:archived_project) { create(:project, :archived, namespace: group) }
    let(:deleted_project) { create(:project, pending_delete: true, namespace: group) }
    let(:group_vulnerability) { create(:vulnerability, :with_findings, project: group_project) }
    let(:subgroup_vulnerability) { create(:vulnerability, :with_findings, project: subgroup_project) }
    let(:archived_vulnerability) { create(:vulnerability, :with_findings, project: archived_project) }
    let(:deleted_vulnerability) { create(:vulnerability, :with_findings, project: deleted_project) }
    let!(:expected_vulnerabilities) do
      [
        group_vulnerability.vulnerability_read,
        subgroup_vulnerability.vulnerability_read,
        archived_vulnerability.vulnerability_read,
        deleted_vulnerability.vulnerability_read
      ]
    end

    it 'returns vulnerabilities for projects in the group and its subgroups' do
      is_expected.to match_array(expected_vulnerabilities)
    end
  end

  describe '#vulnerability_scanners' do
    subject { group.vulnerability_scanners }

    let(:subgroup) { create(:group, parent: group) }
    let(:group_project) { create(:project, namespace: group) }
    let(:subgroup_project) { create(:project, namespace: subgroup) }
    let(:archived_project) { create(:project, :archived, namespace: group) }
    let(:deleted_project) { create(:project, pending_delete: true, namespace: group) }
    let!(:group_vulnerability_scanner) { create(:vulnerabilities_scanner, project: group_project) }
    let!(:subgroup_vulnerability_scanner) { create(:vulnerabilities_scanner, project: subgroup_project) }
    let!(:archived_vulnerability_scanner) { create(:vulnerabilities_scanner, project: archived_project) }
    let!(:deleted_vulnerability_scanner) { create(:vulnerabilities_scanner, project: deleted_project) }

    it 'returns vulnerability scanners for all non-archived, non-deleted projects in the group and its subgroups' do
      is_expected.to contain_exactly(group_vulnerability_scanner, subgroup_vulnerability_scanner)
    end
  end

  describe '#vulnerability_historical_statistics' do
    subject { group.vulnerability_historical_statistics }

    let(:subgroup) { create(:group, parent: group) }
    let(:group_project) { create(:project, namespace: group) }
    let(:subgroup_project) { create(:project, namespace: subgroup) }
    let(:archived_project) { create(:project, :archived, namespace: group) }
    let(:deleted_project) { create(:project, pending_delete: true, namespace: group) }
    let!(:group_vulnerability_historical_statistic) { create(:vulnerability_historical_statistic, project: group_project) }
    let!(:subgroup_vulnerability_historical_statistic) { create(:vulnerability_historical_statistic, project: subgroup_project) }
    let!(:archived_vulnerability_historical_statistic) { create(:vulnerability_historical_statistic, project: archived_project) }
    let!(:deleted_vulnerability_historical_statistic) { create(:vulnerability_historical_statistic, project: deleted_project) }

    it 'returns vulnerability scanners for all non-archived, non-deleted projects in the group and its subgroups' do
      is_expected.to contain_exactly(group_vulnerability_historical_statistic, subgroup_vulnerability_historical_statistic)
    end
  end

  describe '#mark_ldap_sync_as_failed' do
    it 'sets the state to failed' do
      group.start_ldap_sync

      group.mark_ldap_sync_as_failed('Error')

      expect(group).to be_ldap_sync_failed
    end

    it 'sets the error message' do
      group.start_ldap_sync

      group.mark_ldap_sync_as_failed('Something went wrong')

      expect(group.ldap_sync_error).to eq('Something went wrong')
    end

    it 'is graceful when current state is not valid for the fail transition' do
      expect(group).to be_ldap_sync_ready
      expect { group.mark_ldap_sync_as_failed('Error') }.not_to raise_error
    end
  end

  describe '#code_suggestions_enabled?' do
    where(:feature_ai_assist_flag, :code_suggestions, :result) do
      true  | true  | true
      true  | false | false
      false | true  | false
      false | false | false
    end

    subject { group.code_suggestions_enabled? }

    with_them do
      let(:group) do
        build_stubbed(
          :group, namespace_settings: build_stubbed(:namespace_settings, code_suggestions: code_suggestions)
        )
      end

      before do
        stub_feature_flags(ai_assist_flag: feature_ai_assist_flag)
      end

      it { is_expected.to eq(result) }
    end
  end

  describe '#actual_size_limit' do
    let(:group) { build(:group) }

    before do
      allow(::Gitlab::CurrentSettings).to receive(:repository_size_limit).and_return(50)
    end

    it 'returns the value set globally' do
      expect(group.actual_size_limit).to eq(50)
    end

    it 'returns the value set locally' do
      group.update_attribute(:repository_size_limit, 75)

      expect(group.actual_size_limit).to eq(75)
    end
  end

  describe '#repository_size_limit column' do
    it 'support values up to 8 exabytes' do
      group = create(:group)
      group.update_column(:repository_size_limit, 8.exabytes - 1)

      group.reload

      expect(group.repository_size_limit).to eql(8.exabytes - 1)
    end
  end

  describe '#file_template_project' do
    before do
      stub_licensed_features(custom_file_templates_for_namespace: true)
    end

    it { expect(group.private_methods).to include(:file_template_project) }

    context 'validation' do
      let(:project) { create(:project, namespace: group) }

      it 'is cleared if invalid' do
        invalid_project = create(:project)

        group.file_template_project_id = invalid_project.id

        expect(group).to be_valid
        expect(group.file_template_project_id).to be_nil
      end

      it 'is permitted if valid' do
        valid_project = create(:project, namespace: group)

        group.file_template_project_id = valid_project.id

        expect(group).to be_valid
        expect(group.file_template_project_id).to eq(valid_project.id)
      end
    end
  end

  describe '#ip_restriction_ranges' do
    context 'group with no associated ip_restriction records' do
      it 'returns nil' do
        expect(group.ip_restriction_ranges).to eq(nil)
      end
    end

    context 'group with associated ip_restriction records' do
      let(:ranges) { ['192.168.0.0/24', '10.0.0.0/8'] }

      before do
        ranges.each do |range|
          create(:ip_restriction, group: group, range: range)
        end
      end

      it 'returns a comma separated string of ranges of its ip_restriction records' do
        expect(group.ip_restriction_ranges.split(',')).to contain_exactly(*ranges)
      end
    end
  end

  describe '#root_ancestor_ip_restrictions' do
    let(:root_group) { create(:group) }
    let!(:ip_restriction) { create(:ip_restriction, group: root_group) }

    it 'returns the ip restrictions configured for the root group' do
      nested_group = create(:group, parent: root_group)
      deep_nested_group = create(:group, parent: nested_group)
      very_deep_nested_group = create(:group, parent: deep_nested_group)

      expect(root_group.root_ancestor_ip_restrictions).to contain_exactly(ip_restriction)
      expect(nested_group.root_ancestor_ip_restrictions).to contain_exactly(ip_restriction)
      expect(deep_nested_group.root_ancestor_ip_restrictions).to contain_exactly(ip_restriction)
      expect(very_deep_nested_group.root_ancestor_ip_restrictions).to contain_exactly(ip_restriction)
    end
  end

  describe '#allowed_email_domains_list' do
    subject { group.allowed_email_domains_list }

    context 'group with no associated allowed_email_domains records' do
      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'group with associated allowed_email_domains records' do
      let(:domains) { ['acme.com', 'twitter.com'] }

      before do
        domains.each do |domain|
          create(:allowed_email_domain, group: group, domain: domain)
        end
      end

      it 'returns a comma separated string of domains of its allowed_email_domains records' do
        expect(subject).to eq(domains.join(","))
      end
    end
  end

  describe '#root_ancestor_allowed_email_domains' do
    let(:root_group) { create(:group) }
    let!(:allowed_email_domain) { create(:allowed_email_domain, group: root_group) }

    it 'returns the email domain restrictions configured for the root group' do
      nested_group = create(:group, parent: root_group)
      deep_nested_group = create(:group, parent: nested_group)
      very_deep_nested_group = create(:group, parent: deep_nested_group)

      expect(root_group.root_ancestor_allowed_email_domains).to contain_exactly(allowed_email_domain)
      expect(nested_group.root_ancestor_allowed_email_domains).to contain_exactly(allowed_email_domain)
      expect(deep_nested_group.root_ancestor_allowed_email_domains).to contain_exactly(allowed_email_domain)
      expect(very_deep_nested_group.root_ancestor_allowed_email_domains).to contain_exactly(allowed_email_domain)
    end
  end

  describe '#owner_of_email?', :saas do
    let_it_be(:group) { create(:group) }
    let_it_be(:subgroup) { create(:group, parent: group) }
    let_it_be(:project1) { create(:project, group: group) }
    let_it_be(:project2) { create(:project, group: subgroup) }

    let!(:verified_domain) { create(:pages_domain, project: project1) }
    let!(:unverified_domain) { create(:pages_domain, :unverified, project: project2) }

    let(:email_with_verified_domain) { "example@#{verified_domain.domain}" }
    let(:email_with_unverified_domain) { "example@#{unverified_domain.domain}" }

    context 'when domain_verification feature is licensed' do
      before do
        stub_licensed_features(domain_verification: true)
      end

      it 'returns true for email with verified domain' do
        expect(group.owner_of_email?(email_with_verified_domain)).to eq(true)
      end

      it 'returns false for email with unverified domain' do
        expect(group.owner_of_email?(email_with_unverified_domain)).to eq(false)
      end

      it 'ignores case sensitivity' do
        verified_domain.update!(domain: verified_domain.domain.capitalize)

        expect(group.owner_of_email?(email_with_verified_domain.upcase)).to eq(true)
      end

      it 'returns false when the receiver is subgroup' do
        expect(subgroup.owner_of_email?(email_with_verified_domain)).to eq(false)
      end
    end

    context 'when domain_verification feature is not licensed' do
      before do
        stub_licensed_features(domain_verification: false)
      end

      it 'returns false for email with verified domain' do
        expect(group.owner_of_email?(email_with_verified_domain)).to eq(false)
      end
    end
  end

  describe '#predefined_push_rule' do
    context 'group with no associated push_rules record' do
      let!(:sample) { create(:push_rule_sample) }

      it 'returns instance push rule' do
        expect(group.predefined_push_rule).to eq(sample)
      end
    end

    context 'group with associated push_rules record' do
      context 'with its own push rule' do
        let(:push_rule) { create(:push_rule) }

        it 'returns its own push rule' do
          group.update!(push_rule: push_rule)

          expect(group.predefined_push_rule).to eq(push_rule)
        end
      end

      context 'with push rule from ancestor' do
        let(:group) { create(:group, push_rule: push_rule) }
        let(:push_rule) { create(:push_rule) }
        let(:subgroup_1) { create(:group, parent: group) }
        let(:subgroup_1_1) { create(:group, parent: subgroup_1) }

        it 'returns push rule from closest ancestor' do
          expect(subgroup_1_1.predefined_push_rule).to eq(push_rule)
        end
      end
    end

    context 'there are no push rules' do
      it 'returns nil' do
        expect(group.predefined_push_rule).to be_nil
      end
    end
  end

  describe '#checked_file_template_project' do
    let(:valid_project) { create(:project, namespace: group) }

    subject { group.checked_file_template_project }

    context 'licensed' do
      before do
        stub_licensed_features(custom_file_templates_for_namespace: true)
      end

      it 'returns nil for an invalid project' do
        group.file_template_project = create(:project)

        is_expected.to be_nil
      end

      it 'returns a valid project' do
        group.file_template_project = valid_project

        is_expected.to eq(valid_project)
      end
    end

    context 'unlicensed' do
      before do
        stub_licensed_features(custom_file_templates_for_namespace: false)
      end

      it 'returns nil for a valid project' do
        group.file_template_project = valid_project

        is_expected.to be_nil
      end
    end
  end

  describe '#checked_file_template_project_id' do
    let(:valid_project) { create(:project, namespace: group) }

    subject { group.checked_file_template_project_id }

    context 'licensed' do
      before do
        stub_licensed_features(custom_file_templates_for_namespace: true)
      end

      it 'returns nil for an invalid project' do
        group.file_template_project = create(:project)

        is_expected.to be_nil
      end

      it 'returns the ID for a valid project' do
        group.file_template_project = valid_project

        is_expected.to eq(valid_project.id)
      end

      context 'unlicensed' do
        before do
          stub_licensed_features(custom_file_templates_for_namespace: false)
        end

        it 'returns nil for a valid project' do
          group.file_template_project = valid_project

          is_expected.to be_nil
        end
      end
    end
  end

  describe '#group_project_template_available?' do
    subject { group.group_project_template_available? }

    context 'licensed' do
      before do
        stub_licensed_features(group_project_templates: true)
      end

      it 'returns true for licensed instance' do
        is_expected.to be true
      end

      context 'when in need of checking plan', :saas do
        before do
          allow(Gitlab::CurrentSettings.current_application_settings)
            .to receive(:should_check_namespace_plan?).and_return(true)
        end

        it 'returns true for groups in proper plan' do
          create(:gitlab_subscription, :ultimate, namespace: group)

          is_expected.to be true
        end

        it 'returns false for groups with group template already set but not in proper plan' do
          group.update!(custom_project_templates_group_id: create(:group, parent: group).id)
          group.reload

          is_expected.to be false
        end
      end

      context 'unlicensed' do
        before do
          stub_licensed_features(group_project_templates: false)
        end

        it 'returns false for unlicensed instance' do
          is_expected.to be false
        end
      end
    end
  end

  describe '#scoped_variables_available?' do
    let(:group) { create(:group) }

    subject { group.scoped_variables_available? }

    before do
      stub_licensed_features(group_scoped_ci_variables: feature_available)
    end

    context 'licensed feature is available' do
      let(:feature_available) { true }

      it { is_expected.to be true }
    end

    context 'licensed feature is not available' do
      let(:feature_available) { false }

      it { is_expected.to be false }
    end
  end

  describe '#minimal_access_role_allowed?' do
    subject { group.minimal_access_role_allowed? }

    context 'licensed' do
      before do
        stub_licensed_features(minimal_access_role: true)
      end

      it 'returns true for licensed instance' do
        is_expected.to be true
      end

      it 'returns false for subgroup in licensed instance' do
        expect(create(:group, parent: group).minimal_access_role_allowed?).to be false
      end
    end

    context 'unlicensed' do
      before do
        stub_licensed_features(minimal_access_role: false)
      end

      it 'returns false unlicensed instance' do
        is_expected.to be false
      end
    end
  end

  describe '#member?' do
    let(:group) { create(:group) }
    let(:user) { create(:user) }

    subject { group.member?(user) }

    before do
      create(:group_member, :minimal_access, user: user, source: group) if user
    end

    context 'with `minimal_access_role` not licensed' do
      it { is_expected.to be_falsey }
    end

    context 'with `minimal_access_role` licensed' do
      before do
        stub_licensed_features(minimal_access_role: true)
      end

      context 'when group is a subgroup' do
        let(:group) { create(:group, parent: create(:group)) }

        it { is_expected.to be_falsey }
      end

      context 'when group is a top-level group' do
        it { is_expected.to be_truthy }

        it 'accepts higher level as argument' do
          expect(group.member?(user, ::Gitlab::Access::DEVELOPER)).to be_falsey
        end
      end

      context 'with anonymous user' do
        let(:user) { nil }

        it { is_expected.to be_falsey }
      end
    end
  end

  shared_context 'for billable users setup' do
    let_it_be(:group, refind: true) { create(:group_with_plan, plan: :free_plan) }
    let_it_be(:project) { create(:project, namespace: group) }
    let_it_be(:group_developer) { group.add_developer(create(:user)).user }
    let_it_be(:project_developer) { project.add_developer(create(:user)).user }
    let_it_be(:group_guest) { group.add_guest(create(:user)).user }
    let_it_be(:project_guest) { project.add_guest(create(:user)).user }
    let_it_be(:invited_group) { create(:group) }
    let_it_be(:invited_developer) { invited_group.add_developer(create(:user)).user }
    let_it_be(:banned_group_user) { create(:group_member, :banned, :developer, source: group).user }
    let_it_be(:banned_project_user) { create(:project_member, :banned, :developer, source: project).user }

    before_all do
      group.add_maintainer(create(:user, :project_bot))
      project.add_maintainer(create(:user, :project_bot))
      create(:group_group_link, { shared_with_group: invited_group, shared_group: group })
      create(:project_group_link, project: project, group: invited_group)
    end
  end

  describe '#billed_user_ids', :saas do
    include_context 'for billable users setup'

    subject(:billed_user_ids) { group.billed_user_ids }

    context 'with guests' do
      it 'includes distinct active users' do
        expect(billed_user_ids[:user_ids]).to match_array([
                                                            group_guest.id,
                                                            project_guest.id,
                                                            group_developer.id,
                                                            project_developer.id,
                                                            invited_developer.id
                                                          ])
        expect(billed_user_ids[:group_member_user_ids]).to match_array([group_guest.id, group_developer.id])
        expect(billed_user_ids[:project_member_user_ids]).to match_array([project_guest.id, project_developer.id])
        expect(billed_user_ids[:shared_group_user_ids]).to match_array([invited_developer.id])
        expect(billed_user_ids[:shared_project_user_ids]).to match_array([invited_developer.id])
      end

      it 'excludes banned members' do
        expect(billed_user_ids[:user_ids]).to exclude(banned_group_user.id, banned_project_user.id)
        expect(billed_user_ids[:group_member_user_ids]).to exclude(banned_group_user.id)
        expect(billed_user_ids[:project_member_user_ids]).to exclude(banned_project_user.id)
      end
    end

    context 'without guests' do
      before do
        group.gitlab_subscription.update!(hosted_plan: create(:ultimate_plan))
      end

      it 'includes distinct active users' do
        expect(billed_user_ids[:user_ids])
          .to match_array([group_developer.id, project_developer.id, invited_developer.id])
        expect(billed_user_ids[:group_member_user_ids]).to match_array([group_developer.id])
        expect(billed_user_ids[:project_member_user_ids]).to match_array([project_developer.id])
        expect(billed_user_ids[:shared_group_user_ids]).to match_array([invited_developer.id])
        expect(billed_user_ids[:shared_project_user_ids]).to match_array([invited_developer.id])
      end
    end
  end

  describe '#billable_members_count', :saas do
    include_context 'for billable users setup'

    subject(:billable_members_count) { group.billable_members_count }

    context 'with guests' do
      it 'provides count of users' do
        expect(billable_members_count).to eq(5)
      end
    end

    context 'without guests' do
      before do
        group.gitlab_subscription.update!(hosted_plan: create(:ultimate_plan))
      end

      it 'provides count of users' do
        expect(billable_members_count).to eq(3)
      end
    end
  end

  describe '#billed_group_users' do
    let_it_be(:group) { create(:group) }
    let_it_be(:sub_group) { create(:group, parent: group) }
    let_it_be(:sub_developer) { sub_group.add_developer(create(:user)).user }
    let_it_be(:guest) { group.add_guest(create(:user)).user }
    let_it_be(:developer) { group.add_developer(create(:user)).user }

    before_all do
      group.add_developer(create(:user, :blocked))
      group.add_maintainer(create(:user, :project_bot))
      group.add_maintainer(create(:user, :alert_bot))
      group.add_maintainer(create(:user, :support_bot))
      group.add_maintainer(create(:user, :visual_review_bot))
      group.add_maintainer(create(:user, :migration_bot))
      group.add_maintainer(create(:user, :security_bot))
      group.add_maintainer(create(:user, :automation_bot))
      group.add_maintainer(create(:user, :admin_bot))
      create(:group_member, :developer)
      create(:project_member, :developer, source: create(:project, namespace: group))
      create(:group_member, :invited, :developer, source: group)
      create(:group_member, :awaiting, :developer, source: group)
      create(:group_member, :minimal_access, source: group)
      create(:group_member, :access_request, :developer, source: group)
    end

    context 'with guests' do
      it 'includes active users' do
        expect(group.billed_group_users).to match_array([developer, guest, sub_developer])
      end
    end

    context 'without guests' do
      it 'includes active users' do
        expect(group.billed_group_users(exclude_guests: true)).to match_array([developer, sub_developer])
      end
    end

    context 'with member roles' do
      let_it_be(:member_role_elevating) { create(:member_role, :guest, namespace: group) }
      let_it_be(:guest_with_role) { (create :group_member, :guest, source: group, member_role: member_role_elevating).user }

      it 'includes guests with elevating role assigned' do
        expect(MemberRole).to receive(:elevating).at_least(:once).and_return(MemberRole.where(id: member_role_elevating.id))
        expect(group.billed_group_users(exclude_guests: true)).to match_array([developer, sub_developer, guest_with_role])
      end
    end

    context 'with banned members' do
      let_it_be(:banned) { create(:group_member, :banned, :developer, source: group).user }
      let_it_be(:sub_banned) { create(:group_member, :banned, :developer, source: sub_group).user }

      it 'excludes banned members' do
        expect(group.billed_group_users).to exclude(banned, sub_banned)
      end

      context 'when member is banned in one namespace but not another' do
        let_it_be(:another_group) { create(:group) }
        let_it_be(:banned) { create(:group_member, :banned, :developer, source: group).user }

        before do
          another_group.add_developer(banned)
        end

        it 'excludes banned member in the namespace it is banned in' do
          expect(group.billed_group_users).to exclude(banned)
        end

        it 'includes member in the namespace it isn\'t banned in' do
          expect(another_group.billed_group_users).to include(banned)
        end
      end
    end
  end

  describe '#billed_project_users' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, namespace: group) }
    let_it_be(:sub_group_project) { create(:project, namespace: create(:group, parent: group)) }
    let_it_be(:sub_developer) { sub_group_project.add_developer(create(:user)).user }
    let_it_be(:guest) { project.add_guest(create(:user)).user }
    let_it_be(:developer) { project.add_developer(create(:user)).user }

    before_all do
      group.add_developer(create(:user))
      project.add_developer(create(:user, :blocked))
      project.add_maintainer(create(:user, :project_bot))
      project.add_maintainer(create(:user, :alert_bot))
      project.add_maintainer(create(:user, :support_bot))
      project.add_maintainer(create(:user, :visual_review_bot))
      project.add_maintainer(create(:user, :migration_bot))
      project.add_maintainer(create(:user, :security_bot))
      project.add_maintainer(create(:user, :automation_bot))
      project.add_maintainer(create(:user, :admin_bot))
      create(:project_member, :developer)
      create(:project_member, :invited, :developer, source: project)
      create(:project_member, :awaiting, :developer, source: project)
      create(:project_member, :access_request, :developer, source: project)
    end

    context 'with guests' do
      it 'includes active users' do
        expect(group.billed_project_users).to match_array([developer, guest, sub_developer])
      end
    end

    context 'without guests' do
      it 'includes active users' do
        expect(group.billed_project_users(exclude_guests: true)).to match_array([developer, sub_developer])
      end
    end

    context 'with member roles' do
      let_it_be(:member_role_elevating) { create(:member_role, :guest, namespace: group) }
      let_it_be(:guest_with_role) { (create :project_member, :guest, source: project, member_role: member_role_elevating).user }

      it 'includes guests with elevating role assigned' do
        expect(MemberRole).to receive(:elevating).at_least(:once).and_return(MemberRole.where(id: member_role_elevating.id))
        expect(group.billed_project_users(exclude_guests: true)).to match_array([developer, sub_developer, guest_with_role])
      end
    end

    context 'with banned members' do
      let_it_be(:banned) { create(:project_member, :banned, :developer, source: project).user }
      let_it_be(:sub_banned) { create(:project_member, :banned, :developer, source: sub_group_project).user }

      it 'excludes banned members' do
        expect(group.billed_project_users).to exclude(banned, sub_banned)
      end
    end
  end

  describe '#billed_shared_group_users' do
    let_it_be(:group) { create(:group) }
    let_it_be(:sub_group) { create(:group, parent: group) }
    let_it_be(:ancestor_invited_group) { create(:group) }
    let_it_be(:invited_group) { create(:group, parent: ancestor_invited_group) }
    let_it_be(:invited_guest_group) { create(:group) }
    let_it_be(:sub_invited_group) { create(:group) }
    let_it_be(:sub_invited_developer) { sub_invited_group.add_developer(create(:user)).user }
    let_it_be(:invited_developer) { invited_group.add_developer(create(:user)).user }
    let_it_be(:invited_guest) { invited_group.add_guest(create(:user)).user }
    let_it_be(:invited_guest_group_user) { invited_guest_group.add_developer(create(:user)).user }
    let_it_be(:ancestor_invited_developer) { ancestor_invited_group.add_developer(create(:user)).user }

    before_all do
      group.add_developer(create(:user))
      invited_group.add_developer(create(:user, :blocked))
      invited_group.add_maintainer(create(:user, :project_bot))
      invited_group.add_maintainer(create(:user, :alert_bot))
      invited_group.add_maintainer(create(:user, :support_bot))
      invited_group.add_maintainer(create(:user, :visual_review_bot))
      invited_group.add_maintainer(create(:user, :migration_bot))
      invited_group.add_maintainer(create(:user, :security_bot))
      invited_group.add_maintainer(create(:user, :automation_bot))
      invited_group.add_maintainer(create(:user, :admin_bot))
      create(:group_member, :invited, :developer, source: invited_group)
      create(:group_member, :awaiting, :developer, source: invited_group)
      create(:group_member, :minimal_access, source: invited_group)
      create(:group_member, :access_request, :developer, source: invited_group)
      create(:group_group_link, { shared_with_group: sub_invited_group, shared_group: sub_group })
      create(:group_group_link, { shared_with_group: invited_group, shared_group: group })
      create(:group_group_link, :guest, { shared_with_group: invited_guest_group, shared_group: group })
    end

    context 'with guests' do
      it 'includes active users from the other group' do
        expect(group.billed_shared_group_users)
          .to match_array([
                            invited_guest,
                            invited_developer,
                            invited_guest_group_user,
                            ancestor_invited_developer,
                            sub_invited_developer
                          ])
      end
    end

    context 'without guests' do
      it 'includes active users from the other group' do
        expect(group.billed_shared_group_users(exclude_guests: true))
          .to match_array([invited_developer, ancestor_invited_developer, sub_invited_developer])
      end
    end

    context 'with banned members' do
      let_it_be(:banned) { create(:group_member, :banned, :developer, source: group).user }
      let_it_be(:banned_invited_developer) { create(:group_member, :banned, :developer, source: invited_group).user }
      let_it_be(:sub_banned_invited_developer) { create(:group_member, :banned, :developer, source: sub_invited_group).user }

      it 'includes members that are banned in invited group' do
        # currently, if user is banned from "invited_group", they still has access to the linked "group"
        # hence, they are counted as a billable member
        # TODO: https://gitlab.com/gitlab-org/modelops/anti-abuse/team-tasks/-/issues/314
        expect(group.billed_shared_group_users).to include(banned_invited_developer, sub_banned_invited_developer)
      end

      it 'excludes members that are banned in group' do
        expect(group.billed_shared_group_users).to exclude(banned)
      end
    end
  end

  describe '#billed_invited_group_to_project_users' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, namespace: group) }
    let_it_be(:sub_group_project) { create(:project, namespace: create(:group, parent: group)) }
    let_it_be(:ancestor_invited_group) { create(:group) }
    let_it_be(:invited_group) { create(:group, parent: ancestor_invited_group) }
    let_it_be(:invited_guest_group) { create(:group) }
    let_it_be(:sub_invited_group) { create(:group) }
    let_it_be(:sub_invited_developer) { sub_invited_group.add_developer(create(:user)).user }
    let_it_be(:invited_developer) { invited_group.add_developer(create(:user)).user }
    let_it_be(:invited_guest) { invited_group.add_guest(create(:user)).user }
    let_it_be(:invited_guest_group_user) { invited_guest_group.add_developer(create(:user)).user }
    let_it_be(:ancestor_invited_developer) { ancestor_invited_group.add_developer(create(:user)).user }

    before_all do
      group.add_developer(create(:user))
      invited_group.add_developer(create(:user, :blocked))
      invited_group.add_maintainer(create(:user, :project_bot))
      invited_group.add_maintainer(create(:user, :alert_bot))
      invited_group.add_maintainer(create(:user, :support_bot))
      invited_group.add_maintainer(create(:user, :visual_review_bot))
      invited_group.add_maintainer(create(:user, :migration_bot))
      invited_group.add_maintainer(create(:user, :security_bot))
      invited_group.add_maintainer(create(:user, :automation_bot))
      invited_group.add_maintainer(create(:user, :admin_bot))
      create(:group_member, :invited, :developer, source: invited_group)
      create(:group_member, :awaiting, :developer, source: invited_group)
      create(:group_member, :minimal_access, source: invited_group)
      create(:group_member, :access_request, :developer, source: invited_group)
      create(:project_group_link)
      create(:project_group_link, project: project, group: invited_group)
      create(:project_group_link, project: sub_group_project, group: sub_invited_group)
      create(:project_group_link, :guest, project: project, group: invited_guest_group)
    end

    context 'with guests' do
      it 'includes active users from the other group' do
        expect(group.billed_invited_group_to_project_users)
          .to match_array([
                            invited_guest,
                            invited_developer,
                            invited_guest_group_user,
                            ancestor_invited_developer,
                            sub_invited_developer
                          ])
      end
    end

    context 'without guests' do
      it 'includes active users from the other group' do
        expect(group.billed_invited_group_to_project_users(exclude_guests: true))
          .to match_array([invited_developer, ancestor_invited_developer, sub_invited_developer])
      end
    end

    context 'with banned members' do
      let_it_be(:banned) { create(:project_member, :banned, :developer, source: project).user }
      let_it_be(:banned_invited_developer) { create(:group_member, :banned, :developer, source: invited_group).user }
      let_it_be(:sub_banned_invited_developer) { create(:group_member, :banned, :developer, source: sub_invited_group).user }

      it 'includes members that are banned in invited group' do
        # currently, if user is banned from "invited_group", they still has access to the linked "project"
        # hence, they are counted as a billable member
        # TODO: https://gitlab.com/gitlab-org/modelops/anti-abuse/team-tasks/-/issues/314
        expect(group.billed_invited_group_to_project_users).to include(banned_invited_developer, sub_banned_invited_developer)
      end

      it 'excludes members that are banned in group' do
        expect(group.billed_invited_group_to_project_users).to exclude(banned)
      end
    end
  end

  describe '#capacity_left_for_user?' do
    let_it_be(:group) { create(:group) }
    let_it_be(:user) { create(:user) }

    where(:user_cap_available, :user_cap_reached, :existing_membership, :result) do
      false           | false              | false               | true
      false           | false              | true                | true
      false           | true               | true                | true
      true            | false              | false               | true
      true            | false              | true                | true
      true            | true               | true                | true
      true            | true               | false               | false
    end

    subject { group.capacity_left_for_user?(user) }

    with_them do
      before do
        create(:group_member, source: group, user: user) if existing_membership

        allow(group).to receive(:user_cap_available?).and_return(user_cap_available)
        allow(group).to receive(:user_cap_reached?).and_return(user_cap_reached)
      end

      it { is_expected.to eq(result) }
    end
  end

  describe '#has_free_or_no_subscription?', :saas do
    it 'returns true with a free plan' do
      group = create(:group_with_plan, plan: :free_plan)

      expect(group.has_free_or_no_subscription?).to be(true)
    end

    it 'returns false when the plan is not free' do
      group = create(:group_with_plan, plan: :ultimate_plan)

      expect(group.has_free_or_no_subscription?).to be(false)
    end

    it 'returns true when there is no plan' do
      group = create(:group)

      expect(group.has_free_or_no_subscription?).to be(true)
    end

    it 'returns true when there is a subscription with no plan' do
      group = create(:group)
      create(:gitlab_subscription, hosted_plan: nil, namespace: group)

      expect(group.has_free_or_no_subscription?).to be(true)
    end

    context 'when it is a subgroup' do
      let(:subgroup) { create(:group, parent: group) }

      context 'with a free plan' do
        let(:group) { create(:group_with_plan, plan: :free_plan) }

        it 'returns true' do
          expect(subgroup.has_free_or_no_subscription?).to be(true)
        end
      end

      context 'with a plan that is not free' do
        let(:group) { create(:group_with_plan, plan: :ultimate_plan) }

        it 'returns false' do
          expect(subgroup.has_free_or_no_subscription?).to be(false)
        end
      end

      context 'when there is no plan' do
        let(:group) { create(:group) }

        it 'returns true' do
          expect(subgroup.has_free_or_no_subscription?).to be(true)
        end
      end

      context 'when there is a subscription with no plan' do
        let(:group) { create(:group) }

        before do
          create(:gitlab_subscription, hosted_plan: nil, namespace: group)
        end

        it 'returns true' do
          expect(subgroup.has_free_or_no_subscription?).to be(true)
        end
      end
    end
  end

  describe '#enforce_free_user_cap?' do
    let(:group) { build(:group) }

    where(:enforce_free_cap, :result) do
      false | false
      true  | true
    end

    subject { group.enforce_free_user_cap? }

    with_them do
      specify do
        expect_next_instance_of(Namespaces::FreeUserCap::Enforcement, group) do |instance|
          expect(instance).to receive(:enforce_cap?).and_return(enforce_free_cap)
        end

        is_expected.to eq(result)
      end
    end
  end

  describe '#exclude_guests?', :saas do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:group, refind: true) { create(:group) }

    where(:actual_plan_name, :requested_plan_name, :result) do
      :free           | nil        | false
      :premium        | nil        | false
      :ultimate       | nil        | true
      :ultimate_trial | nil        | true
      :gold           | nil        | true

      :free           | 'premium'  | false
      :free           | 'ultimate' | true
      :premium        | 'ultimate' | true
      :ultimate       | 'ultimate' | true
    end

    with_them do
      let!(:subscription) { build(:gitlab_subscription, actual_plan_name, namespace: group) }

      it 'returns the expected result' do
        expect(group.exclude_guests?(requested_plan_name)).to eq(result)
      end
    end
  end

  describe '#actual_plan_name', :saas do
    let_it_be(:parent) { create(:group) }
    let_it_be(:subgroup, refind: true) { create(:group, parent: parent) }

    subject(:actual_plan_name) { subgroup.actual_plan_name }

    context 'when parent group has a subscription associated' do
      before do
        create(:gitlab_subscription, :ultimate, namespace: parent)
      end

      it 'returns an associated plan name' do
        expect(actual_plan_name).to eq 'ultimate'
      end
    end

    context 'when parent group does not have subscription associated' do
      it 'returns a free plan name' do
        expect(actual_plan_name).to eq 'free'
      end
    end
  end

  describe '#users_count' do
    subject { group.users_count }

    let(:group) { create(:group) }
    let(:user) { create(:user) }

    context 'with `minimal_access_role` not licensed' do
      before do
        stub_licensed_features(minimal_access_role: false)
        create(:group_member, :minimal_access, user: user, source: group)
      end

      it 'does not count the minimal access user' do
        expect(group.users_count).to eq(0)
      end
    end

    context 'with `minimal_access_role` licensed' do
      before do
        stub_licensed_features(minimal_access_role: true)
        create(:group_member, :minimal_access, user: user, source: group)
      end

      it 'counts the minimal access user' do
        expect(group.users_count).to eq(1)
      end
    end
  end

  describe '#saml_discovery_token' do
    it 'returns existing tokens' do
      group = create(:group, saml_discovery_token: 'existing')

      expect(group.saml_discovery_token).to eq 'existing'
    end

    context 'when missing on read' do
      it 'generates a token' do
        expect(group.saml_discovery_token.length).to eq 8
      end

      it 'saves the generated token' do
        expect { group.saml_discovery_token }.to change { group.reload.read_attribute(:saml_discovery_token) }
      end

      context 'in read-only mode' do
        before do
          allow(Gitlab::Database).to receive(:read_only?).and_return(true)
          allow(group).to receive(:create_or_update).and_raise(ActiveRecord::ReadOnlyRecord)
        end

        it "doesn't raise an error as that could expose group existance" do
          expect { group.saml_discovery_token }.not_to raise_error
        end

        it 'returns a random value to prevent access' do
          expect(group.saml_discovery_token).not_to be_blank
        end
      end
    end
  end

  describe '#saml_enabled?' do
    subject { group.saml_enabled? }

    context 'when a SAML provider does not exist' do
      it { is_expected.to eq(false) }
    end

    context 'when a SAML provider exists and is persisted' do
      before do
        create(:saml_provider, group: group)
      end

      it { is_expected.to eq(true) }
    end

    context 'when a SAML provider is not persisted' do
      before do
        build(:saml_provider, group: group)
      end

      it { is_expected.to eq(false) }
    end

    context 'when global SAML is enabled' do
      before do
        allow(Gitlab::Auth::OAuth::Provider).to receive(:providers).and_return([:saml])
      end

      it { is_expected.to eq(true) }
    end
  end

  describe '#saml_group_sync_available?' do
    subject { group.saml_group_sync_available? }

    it { is_expected.to eq(false) }

    context 'with group_saml_group_sync feature licensed' do
      before do
        stub_licensed_features(saml_group_sync: true)
      end

      it { is_expected.to eq(false) }

      context 'with saml enabled' do
        before do
          create(:saml_provider, group: group, enabled: true)
        end

        it { is_expected.to eq(true) }

        context 'when the group is a subgroup' do
          let(:subgroup) { create(:group, :private, parent: group) }

          subject { subgroup.saml_group_sync_available? }

          it { is_expected.to eq(true) }
        end
      end
    end
  end

  describe '#saml_group_links_enabled?' do
    subject { group.saml_group_links_enabled? }

    context 'with group saml disabled' do
      it { is_expected.to eq(false) }
    end

    context 'with group saml enabled' do
      before do
        create(:saml_provider, group: group)
      end

      context "without saml group links" do
        it { is_expected.to eq(false) }
      end

      context 'with saml group links' do
        before do
          create(:saml_group_link, group: group)
        end

        it { is_expected.to eq(true) }
      end
    end
  end

  describe "#insights_config" do
    context 'when group has no Insights project configured' do
      it 'returns the default config' do
        expect(group.insights_config).to eq(group.default_insights_config)
      end
    end

    context 'when group has an Insights project configured without a config file' do
      before do
        project = create(:project, group: group)
        group.create_insight!(project: project)
      end

      it 'returns the default config' do
        expect(group.insights_config).to eq(group.default_insights_config)
      end
    end

    context 'when group has an Insights project configured' do
      before do
        project = create(:project, :custom_repo, group: group, files: { ::Gitlab::Insights::CONFIG_FILE_PATH => insights_file_content })
        group.create_insight!(project: project)
      end

      context 'with a valid config file' do
        let(:insights_file_content) { 'key: monthlyBugsCreated' }

        it 'returns the insights config data' do
          insights_config = group.insights_config

          expect(insights_config).to eq(key: 'monthlyBugsCreated')
        end
      end

      context 'with an invalid config file' do
        let(:insights_file_content) { ': foo bar' }

        it 'returns nil' do
          expect(group.insights_config).to be_nil
        end
      end
    end

    context 'when group has an Insights project configured which is in a nested group' do
      before do
        nested_group = create(:group, parent: group)
        project = create(:project, :custom_repo, group: nested_group, files: { ::Gitlab::Insights::CONFIG_FILE_PATH => insights_file_content })
        group.create_insight!(project: project)
      end

      let(:insights_file_content) { 'key: monthlyBugsCreated' }

      it 'returns the insights config data' do
        insights_config = group.insights_config

        expect(insights_config).to eq(key: 'monthlyBugsCreated')
      end
    end
  end

  describe '#any_hook_failed?' do
    let_it_be(:group) { create(:group) }

    subject { group.any_hook_failed? }

    it { is_expected.to eq(false) }
  end

  describe "#execute_hooks" do
    context "group_webhooks", :request_store do
      let_it_be(:parent_group) { create(:group) }
      let_it_be(:group) { create(:group, parent: parent_group) }
      let_it_be(:group_hook) { create(:group_hook, group: group, member_events: true) }
      let_it_be(:parent_group_hook) { create(:group_hook, group: parent_group, member_events: true) }

      let(:data) { { some: 'info' } }

      context 'when group_webhooks feature is enabled' do
        before do
          stub_licensed_features(group_webhooks: true)
        end

        context 'execution' do
          it 'executes the hook for self and ancestor groups by default' do
            expect(WebHookService).to receive(:new)
                                        .with(group_hook, data, 'member_hooks').and_call_original
            expect(WebHookService).to receive(:new)
                                        .with(parent_group_hook, data, 'member_hooks').and_call_original

            group.execute_hooks(data, :member_hooks)
          end
        end

        context 'when a hook has recent failures' do
          before do
            group_hook.update!(recent_failures: 4)
          end

          it 'is still executed' do
            expect(WebHookService).to receive(:new)
                                        .with(group_hook, data, 'member_hooks').and_call_original
            expect(WebHookService).to receive(:new)
                                        .with(parent_group_hook, data, 'member_hooks').and_call_original

            group.execute_hooks(data, :member_hooks)
          end
        end
      end

      context 'when group_webhooks feature is disabled' do
        before do
          stub_licensed_features(group_webhooks: false)
        end

        it 'does not execute the hook' do
          expect(WebHookService).not_to receive(:new)

          group.execute_hooks(data, :member_hooks)
        end
      end
    end
  end

  context 'subgroup hooks', :sidekiq_inline do
    let_it_be(:grandparent_group) { create(:group) }
    let_it_be(:parent_group) { create(:group, parent: grandparent_group) }
    let_it_be(:subgroup) { create(:group, parent: parent_group) }
    let_it_be(:parent_group_hook) { create(:group_hook, group: parent_group, subgroup_events: true) }

    def webhook_body(subgroup:, parent_group:, event_name:)
      {
        created_at: subgroup.created_at.xmlschema,
        updated_at: subgroup.updated_at.xmlschema,
        name: subgroup.name,
        path: subgroup.path,
        full_path: subgroup.full_path,
        group_id: subgroup.id,
        parent_name: parent_group.name,
        parent_path: parent_group.path,
        parent_full_path: parent_group.full_path,
        parent_group_id: parent_group.id,
        event_name: event_name
      }
    end

    def webhook_headers
      {
        'Content-Type' => 'application/json',
        'User-Agent' => "GitLab/#{Gitlab::VERSION}",
        'X-Gitlab-Event' => 'Subgroup Hook'
      }
    end

    before do
      WebMock.stub_request(:post, parent_group_hook.url)
    end

    context 'when a subgroup is added to the parent group' do
      it 'executes the webhook' do
        subgroup = create(:group, parent: parent_group)

        expect(WebMock).to have_requested(:post, parent_group_hook.url).with(
          headers: webhook_headers,
          body: webhook_body(subgroup: subgroup, parent_group: parent_group, event_name: 'subgroup_create')
        )
      end
    end

    context 'when a subgroup is removed from the parent group' do
      it 'executes the webhook' do
        subgroup.destroy!

        expect(WebMock).to have_requested(:post, parent_group_hook.url).with(
          headers: webhook_headers,
          body: webhook_body(subgroup: subgroup, parent_group: parent_group, event_name: 'subgroup_destroy')
        )
      end
    end

    context 'when the subgroup has subgroup webhooks enabled' do
      let_it_be(:subgroup_hook) { create(:group_hook, group: subgroup, subgroup_events: true) }

      it 'does not execute the webhook on itself' do
        subgroup.destroy!

        expect(WebMock).not_to have_requested(:post, subgroup_hook.url)
      end
    end

    context 'ancestor groups' do
      let_it_be(:grand_parent_group_hook) { create(:group_hook, group: grandparent_group, subgroup_events: true) }

      before do
        WebMock.stub_request(:post, grand_parent_group_hook.url)
      end

      it 'fires webhook twice when both parent & grandparent group has subgroup_events enabled' do
        subgroup.destroy!

        expect(WebMock).to have_requested(:post, grand_parent_group_hook.url)
        expect(WebMock).to have_requested(:post, parent_group_hook.url)
      end

      context 'when parent group does not have subgroup_events enabled' do
        before do
          parent_group_hook.update!(subgroup_events: false)
        end

        it 'fires webhook once for the grandparent group when it has subgroup_events enabled' do
          subgroup.destroy!

          expect(WebMock).to have_requested(:post, grand_parent_group_hook.url)
          expect(WebMock).not_to have_requested(:post, parent_group_hook.url)
        end
      end
    end

    context 'when the group is not a subgroup' do
      let_it_be(:grand_parent_group_hook) { create(:group_hook, group: grandparent_group, subgroup_events: true) }

      it 'does not proceed to firing any webhooks' do
        allow(grandparent_group).to receive(:execute_hooks)

        grandparent_group.destroy!

        expect(grandparent_group).not_to have_received(:execute_hooks)
      end
    end

    context 'when group webhooks are unlicensed' do
      before do
        stub_licensed_features(group_webhooks: false)
      end

      it 'does not execute the webhook' do
        subgroup.destroy!

        expect(WebMock).not_to have_requested(:post, parent_group_hook.url)
      end
    end
  end

  describe '#self_or_ancestor_marked_for_deletion' do
    context 'delayed deletion feature is not available' do
      before do
        stub_licensed_features(adjourned_deletion_for_projects_and_groups: false)
        create(:group_deletion_schedule, group: group, marked_for_deletion_on: 1.day.ago)
      end

      it 'returns nil' do
        expect(group.self_or_ancestor_marked_for_deletion).to be_nil
      end
    end

    context 'delayed deletion feature is available' do
      before do
        stub_licensed_features(adjourned_deletion_for_projects_and_groups: true)
      end

      context 'the group has been marked for deletion' do
        before do
          create(:group_deletion_schedule, group: group, marked_for_deletion_on: 1.day.ago)
        end

        it 'returns the group' do
          expect(group.self_or_ancestor_marked_for_deletion).to eq(group)
        end
      end

      context 'the parent group has been marked for deletion' do
        let(:parent_group) { create(:group_with_deletion_schedule, marked_for_deletion_on: 1.day.ago) }
        let(:group) { create(:group, parent: parent_group) }

        it 'returns the parent group' do
          expect(group.self_or_ancestor_marked_for_deletion).to eq(parent_group)
        end
      end

      context 'no group has been marked for deletion' do
        let(:parent_group) { create(:group) }
        let(:group) { create(:group, parent: parent_group) }

        it 'returns nil' do
          expect(group.self_or_ancestor_marked_for_deletion).to be_nil
        end
      end

      context 'ordering' do
        let(:group_a) { create(:group_with_deletion_schedule, marked_for_deletion_on: 1.day.ago) }
        let(:subgroup_a) { create(:group_with_deletion_schedule, marked_for_deletion_on: 1.day.ago, parent: group_a) }
        let(:group) { create(:group, parent: subgroup_a) }

        it 'returns the first group that is marked for deletion, up its ancestry chain' do
          expect(group.self_or_ancestor_marked_for_deletion).to eq(subgroup_a)
        end
      end
    end
  end

  describe '#marked_for_deletion?' do
    subject { group.marked_for_deletion? }

    context 'delayed deletion feature is available' do
      before do
        stub_licensed_features(adjourned_deletion_for_projects_and_groups: true)
      end

      context 'when the group is marked for delayed deletion' do
        before do
          create(:group_deletion_schedule, group: group, marked_for_deletion_on: 1.day.ago)
        end

        it { is_expected.to be_truthy }
      end

      context 'when the group is not marked for delayed deletion' do
        it { is_expected.to be_falsey }
      end
    end

    context 'delayed deletion feature is not available' do
      before do
        stub_licensed_features(adjourned_deletion_for_projects_and_groups: false)
      end

      context 'when the group is marked for delayed deletion' do
        before do
          create(:group_deletion_schedule, group: group, marked_for_deletion_on: 1.day.ago)
        end

        it { is_expected.to be_falsey }
      end

      context 'when the group is not marked for delayed deletion' do
        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#adjourned_deletion?' do
    subject { group.adjourned_deletion? }

    shared_examples_for 'returns false' do
      it { is_expected.to be_falsey }
    end

    shared_examples_for 'returns true' do
      it { is_expected.to be_truthy }
    end

    context 'delayed deletion feature is available' do
      where(:adjourned_period, :delayed_group_deletion, :always_perform_delayed_deletion, :expected) do
        0 | true  | true  | false
        0 | false | true  | false
        1 | true  | true  | true
        1 | false | true  | true
        0 | true  | false | false
        0 | false | false | false
        1 | true  | false | true
        1 | false | false | false
      end

      with_them do
        before do
          stub_licensed_features(adjourned_deletion_for_projects_and_groups: true)
          stub_application_setting(deletion_adjourned_period: adjourned_period)
          stub_application_setting(delayed_group_deletion: delayed_group_deletion)
          stub_feature_flags(always_perform_delayed_deletion: always_perform_delayed_deletion)
        end

        it { is_expected.to expected ? be_truthy : be_falsey }
      end
    end

    context 'delayed deletion feature is not available' do
      before do
        stub_licensed_features(adjourned_deletion_for_projects_and_groups: false)
      end

      context 'when delayed deletion period is set to more than 0' do
        before do
          stub_application_setting(delayed_group_deletion: false)
        end

        it_behaves_like 'returns false'
      end
    end
  end

  describe '#personal_access_token_expiration_policy_available?' do
    subject { group.personal_access_token_expiration_policy_available? }

    let(:group) { build(:group) }

    context 'when the group does not enforce managed accounts' do
      it { is_expected.to be_falsey }
    end

    context 'when the group enforces managed accounts' do
      before do
        allow(group).to receive(:enforced_group_managed_accounts?).and_return(true)
      end

      context 'with `personal_access_token_expiration_policy` licensed' do
        before do
          stub_licensed_features(personal_access_token_expiration_policy: true)
        end

        it { is_expected.to be_truthy }
      end

      context 'with `personal_access_token_expiration_policy` not licensed' do
        before do
          stub_licensed_features(personal_access_token_expiration_policy: false)
        end

        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#update_personal_access_tokens_lifetime' do
    subject { group.update_personal_access_tokens_lifetime }

    let(:limit) { 1 }
    let(:group) { build(:group, max_personal_access_token_lifetime: limit) }

    shared_examples_for 'it does not call the update lifetime service' do
      it 'doesn not call the update lifetime service' do
        expect(::PersonalAccessTokens::Groups::UpdateLifetimeService).not_to receive(:new)

        subject
      end
    end

    context 'when the group does not enforce managed accounts' do
      it_behaves_like 'it does not call the update lifetime service'
    end

    context 'when the group enforces managed accounts' do
      before do
        allow(group).to receive(:enforced_group_managed_accounts?).and_return(true)
      end

      context 'with `personal_access_token_expiration_policy` not licensed' do
        before do
          stub_licensed_features(personal_access_token_expiration_policy: false)
        end

        it_behaves_like 'it does not call the update lifetime service'
      end

      context 'with `personal_access_token_expiration_policy` licensed' do
        before do
          stub_licensed_features(personal_access_token_expiration_policy: true)
        end

        context 'when the group does not enforce a PAT expiry policy' do
          let(:limit) { nil }

          it_behaves_like 'it does not call the update lifetime service'
        end

        context 'when the group enforces a PAT expiry policy' do
          it 'executes the update lifetime service' do
            expect_next_instance_of(::PersonalAccessTokens::Groups::UpdateLifetimeService, group) do |service|
              expect(service).to receive(:execute)
            end

            subject
          end
        end
      end
    end
  end

  describe '#max_personal_access_token_lifetime_from_now' do
    subject { group.max_personal_access_token_lifetime_from_now }

    let(:days_from_now) { nil }
    let(:group) { build(:group, max_personal_access_token_lifetime: days_from_now) }

    context 'when max_personal_access_token_lifetime is defined' do
      let(:days_from_now) { 30 }

      it 'is a date time' do
        expect(subject).to be_a Time
      end

      it 'is in the future' do
        expect(subject).to be > Time.zone.now
      end

      it 'is in days_from_now' do
        expect(subject.to_date - Date.today).to eq days_from_now
      end
    end

    context 'when max_personal_access_token_lifetime is nil' do
      it 'is nil' do
        expect(subject).to be_nil
      end
    end
  end

  describe '#owners_emails' do
    let(:user) { create(:user, email: 'bob@example.com') }

    before do
      group.add_owner(user)
    end

    subject { group.owners_emails }

    it { is_expected.to match([user.email]) }
  end

  describe "#access_level_roles" do
    let(:group) { create(:group) }

    before do
      stub_licensed_features(minimal_access_role: true)
    end

    it "returns the correct roles" do
      expect(group.access_level_roles).to eq(
        {
          "Minimal Access" => 5,
          "Guest" => 10,
          "Reporter" => 20,
          "Developer" => 30,
          "Maintainer" => 40,
          "Owner" => 50
        }
      )
    end
  end

  describe 'Releases Stats' do
    context 'when there are no releases' do
      describe '#releases_count' do
        it 'returns 0' do
          expect(group.releases_count).to eq(0)
        end
      end

      describe '#releases_percentage' do
        it 'returns 0 and does not attempt to divide by 0' do
          expect(group.releases_percentage).to eq(0)
        end
      end
    end

    context 'when there are some releases' do
      before do
        subgroup_1 = create(:group, parent: group)
        subgroup_2 = create(:group, parent: subgroup_1)

        project_in_group = create(:project, group: group)
        _project_in_subgroup_1 = create(:project, group: subgroup_1)
        project_in_subgroup_2 = create(:project, group: subgroup_2)
        project_in_unrelated_group = create(:project)

        create(:release, project: project_in_group)
        create(:release, project: project_in_subgroup_2)
        create(:release, project: project_in_unrelated_group)
      end

      describe '#releases_count' do
        it 'counts all releases for group and descendants' do
          expect(group.releases_count).to eq(2)
        end
      end

      describe '#releases_percentage' do
        it 'calculates projects with releases percentage for group and descendants' do
          # 2 out of 3 projects have releases
          expect(group.releases_percentage).to eq(67)
        end
      end
    end
  end

  describe '#repository_storage', :aggregate_failures do
    context 'when wiki does not have a tracked repository storage' do
      it 'returns the default shard' do
        expect(::Repository).to receive(:pick_storage_shard).and_call_original
        expect(subject.repository_storage).to eq('default')
      end
    end

    context 'when wiki has a tracked repository storage' do
      it 'returns the persisted shard' do
        group.wiki.create_wiki_repository

        expect(group.group_wiki_repository).to receive(:shard_name).and_return('foo')

        expect(group.repository_storage).to eq('foo')
      end
    end
  end

  describe '#user_cap_reached?' do
    subject(:user_cap_reached_for_group?) { group.user_cap_reached? }

    context 'when user cap feature is not available' do
      before do
        allow(group).to receive(:user_cap_available?).and_return(false)
      end

      it { is_expected.to be_falsey }
    end

    context 'when user cap feature is available' do
      before do
        allow(group).to receive(:user_cap_available?).and_return(true)
      end

      context 'when the :saas_user_caps feature flag is not enabled' do
        it { is_expected.to be_falsey }
      end

      context 'when the :saas_user_caps feature flag is enabled' do
        before do
          stub_feature_flags(saas_user_caps: true)
        end

        let(:new_user_signups_cap) { nil }

        shared_examples 'returning the right value for user_cap_reached?' do
          before do
            allow(root_group).to receive(:user_cap_available?).and_return(true)
            root_group.namespace_settings.update!(new_user_signups_cap: new_user_signups_cap)
          end

          context 'when no user cap has been set to that root ancestor' do
            it { is_expected.to be_falsey }
          end

          context 'when a user cap has been set to that root ancestor' do
            let(:new_user_signups_cap) { 100 }

            before do
              allow(root_group).to receive(:billable_members_count).and_return(billable_members_count)
              allow(group).to receive(:root_ancestor).and_return(root_group)
            end

            context 'when this cap is higher than the number of billable members' do
              let(:billable_members_count) { new_user_signups_cap - 10 }

              it { is_expected.to be_falsey }
            end

            context 'when this cap is the same as the number of billable members' do
              let(:billable_members_count) { new_user_signups_cap }

              it { is_expected.to be_truthy }
            end

            context 'when this cap is lower than the number of billable members' do
              let(:billable_members_count) { new_user_signups_cap + 10 }

              it { is_expected.to be_truthy }
            end
          end
        end

        context 'when this group has no root ancestor' do
          it_behaves_like 'returning the right value for user_cap_reached?' do
            let(:root_group) { group }
          end
        end

        context 'when this group has a root ancestor' do
          it_behaves_like 'returning the right value for user_cap_reached?' do
            let(:root_group) { create(:group, children: [group]) }
          end
        end
      end
    end
  end

  describe '#calculate_reactive_cache' do
    let(:group) { build(:group) }

    subject { group.calculate_reactive_cache }

    it 'returns cache data for the free plan members count' do
      expect(group).to receive(:billable_members_count).and_return(5)

      is_expected.to eq(5)
    end
  end

  describe '#shared_externally?' do
    let_it_be(:group, refind: true) { create(:group) }
    let_it_be(:subgroup_1) { create(:group, parent: group) }
    let_it_be(:subgroup_2) { create(:group, parent: group) }
    let_it_be(:external_group) { create(:group) }
    let_it_be(:project) { create(:project, group: subgroup_1) }

    subject(:shared_externally?) { group.shared_externally? }

    it 'returns false when the group is not shared outside of the namespace hierarchy' do
      expect(shared_externally?).to be false
    end

    it 'returns true when the group is shared outside of the namespace hierarchy' do
      create(:group_group_link, shared_group: group, shared_with_group: external_group)

      expect(shared_externally?).to be true
    end

    it 'returns false when the group is shared internally within the namespace hierarchy' do
      create(:group_group_link, shared_group: subgroup_1, shared_with_group: subgroup_2)

      expect(shared_externally?).to be false
    end

    it 'returns true when a subgroup is shared outside of the namespace hierarchy' do
      create(:group_group_link, shared_group: subgroup_1, shared_with_group: external_group)

      expect(shared_externally?).to be true
    end

    it 'returns false when the only shared groups are outside of the namespace hierarchy' do
      create(:group_group_link)

      expect(shared_externally?).to be false
    end

    it 'returns true when the group project is shared outside of the namespace hierarchy' do
      create(:project_group_link, project: project, group: external_group)

      expect(shared_externally?).to be true
    end

    it 'returns false when the group project is only shared internally within the namespace hierarchy' do
      create(:project_group_link, project: project, group: subgroup_2)

      expect(shared_externally?).to be false
    end
  end

  it_behaves_like 'can move repository storage' do
    let_it_be(:container) { create(:group, :wiki_repo) }

    let(:repository) { container.wiki.repository }
  end

  describe '#cluster_agents' do
    let_it_be(:other_group) { create(:group) }
    let_it_be(:other_project) { create(:project, namespace: other_group) }

    let_it_be(:root_group) { create(:group) }
    let_it_be(:subgroup) { create(:group, parent: root_group) }
    let_it_be(:project_in_group) { create(:project, namespace: root_group) }
    let_it_be(:project_in_subgroup) { create(:project, namespace: subgroup) }

    let_it_be(:cluster_agent_for_other_project) { create(:cluster_agent, project: other_project) }
    let_it_be(:cluster_agent_for_project) { create(:cluster_agent, project: project_in_group) }
    let_it_be(:cluster_agent_for_project_in_subgroup) { create(:cluster_agent, project: project_in_subgroup) }

    subject { root_group.cluster_agents }

    it { is_expected.to contain_exactly(cluster_agent_for_project, cluster_agent_for_project_in_subgroup) }
  end

  describe '#unique_project_download_limit_enabled?' do
    let_it_be(:group) { create(:group) }

    let(:feature_flag_enabled) { true }
    let(:licensed_feature_available) { true }

    before do
      stub_feature_flags(limit_unique_project_downloads_per_namespace_user: feature_flag_enabled)
      stub_licensed_features(unique_project_download_limit: licensed_feature_available)
    end

    subject { group.unique_project_download_limit_enabled? }

    it { is_expected.to eq true }

    context 'when feature flag is disabled' do
      let(:feature_flag_enabled) { false }

      it { is_expected.to eq false }
    end

    context 'when licensed feature is not available' do
      let(:licensed_feature_available) { false }

      it { is_expected.to eq false }
    end

    context 'when sub-group' do
      let(:subgroup) { create(:group, parent: group) }

      subject { subgroup.unique_project_download_limit_enabled? }

      it { is_expected.to eq false }
    end
  end

  describe '#parent_epic_ids_in_ancestor_groups' do
    let_it_be(:root_group) { create(:group) }
    let_it_be(:group) { create(:group, parent: root_group) }
    let_it_be(:subgroup) { create(:group, parent: group) }
    let_it_be(:root_epic) { create(:epic, group: root_group) }
    let_it_be(:unrelated_epic) { create(:epic, group: root_group) }
    let_it_be(:epic) { create(:epic, group: group) }
    let_it_be(:subepic1) { create(:epic, parent: root_epic, group: subgroup) }
    let_it_be(:subepic2) { create(:epic, parent: epic, group: subgroup) }
    let_it_be(:subepic3) { create(:epic, parent: subepic1, group: subgroup) }

    it 'returns parent ids of epics of the given group that belongs to ancestor groups' do
      stub_const('Group::EPIC_BATCH_SIZE', 1)

      expect(subgroup.parent_epic_ids_in_ancestor_groups).to match_array([epic.id, root_epic.id])
    end
  end

  describe '#usage_quotas_enabled?', feature_category: :consumables_cost_management do
    using RSpec::Parameterized::TableSyntax

    where(:feature_available, :feature_enabled, :root_group, :result) do
      false | true  | true  | true
      true  | true  | true  | true
      true  | false | true  | true
      false | false | true  | false
      false | false | false | false
      false | true  | false | false
      true  | false | false | false
      true  | true  | false | false
    end

    with_them do
      before do
        stub_licensed_features(usage_quotas: feature_available)
        stub_feature_flags(usage_quotas_for_all_editions: feature_enabled)
        allow(group).to receive(:root?).and_return(root_group)
      end

      it 'returns the expected result' do
        expect(group.usage_quotas_enabled?).to eq result
      end
    end
  end

  describe '#sbom_occurrences' do
    subject { group.sbom_occurrences }

    it { is_expected.to be_empty }

    context 'with project' do
      let!(:project) { create(:project, group: group) }

      it { is_expected.to be_empty }

      context 'with occurrences' do
        let!(:sbom_occurence) { create(:sbom_occurrence, project: project) }

        it { is_expected.to eq [sbom_occurence] }
      end
    end
  end
end
