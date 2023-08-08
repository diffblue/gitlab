# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemAccess::SamlMicrosoftGroupSyncWorker, :aggregate_failures, feature_category: :system_access do
  describe '#perform' do
    let(:worker) { described_class.new }

    let_it_be(:user_no_identity) { create(:user) }
    let_it_be(:user_with_identity) { create(:user) }
    let_it_be(:identity) { create(:identity, user: user_with_identity, provider: 'saml') }

    let_it_be_with_refind(:application) do
      create(:system_access_microsoft_application, namespace: nil)
    end

    let_it_be(:group1) { create(:group) }
    let_it_be(:subgroup1) { create(:group, parent: group1) }
    let_it_be(:group2) { create(:group) }
    let_it_be(:group3) { create(:group) }

    let_it_be(:org_users) { 'Org Users' }
    let_it_be(:dept_users) { 'Dept Users' }
    let_it_be(:all_groups) { [org_users, dept_users] }
    let_it_be(:no_groups) { [] }

    let_it_be(:group_link1) { create(:saml_group_link, group: group1, saml_group_name: org_users) }
    let_it_be(:subgroup1_link) { create(:saml_group_link, group: subgroup1, saml_group_name: dept_users) }

    let_it_be(:group_link2) { create(:saml_group_link, group: group2, saml_group_name: org_users) }

    using RSpec::Parameterized::TableSyntax

    # Test every combination of preconditions to ensure sync does not execute unless all are met.
    where(:sync_enabled, :app_enabled, :user, :microsoft_groups, :expect_sync_service_called_times) do
      false | false | ref(:user_no_identity) | ref(:no_groups)    | 0
      false | true  | ref(:user_no_identity) | ref(:no_groups)    | 0
      true  | false | ref(:user_no_identity) | ref(:no_groups)    | 0
      true  | true  | ref(:user_no_identity) | ref(:no_groups)    | 0

      false | false | ref(:user_no_identity) | ref(:all_groups)   | 0
      true  | false | ref(:user_no_identity) | ref(:all_groups)   | 0
      false | true  | ref(:user_no_identity) | ref(:all_groups)   | 0
      true  | true  | ref(:user_no_identity) | ref(:all_groups)   | 0

      false | false | ref(:user_with_identity) | ref(:no_groups)  | 0
      false | true  | ref(:user_with_identity) | ref(:no_groups)  | 0
      true  | false | ref(:user_with_identity) | ref(:no_groups)  | 0
      true  | true  | ref(:user_with_identity) | ref(:no_groups)  | 0

      false | false | ref(:user_with_identity) | ref(:all_groups) | 0
      true  | false | ref(:user_with_identity) | ref(:all_groups) | 0
      false | true  | ref(:user_with_identity) | ref(:all_groups) | 0

      # This is the only scenario that satisfies all preconditions.
      # Sync is called once per top-level group. Since we have 3 group links in 2
      # top-level group hierarchies, we expect sync service to be called twice.
      true  | true  | ref(:user_with_identity) | ref(:all_groups) | 2
    end

    with_them do
      before do
        stub_sync_enabled(sync_enabled)
        application.update!(enabled: app_enabled)
        stub_microsoft_groups(microsoft_groups)
      end

      it 'calls the sync service the appropriate number of times' do
        expect(Groups::SyncService).to receive(:new).exactly(expect_sync_service_called_times).times.and_call_original

        worker.perform(user.id)
      end
    end

    # More in-depth verification of how sync service is called and the outcomes of sync.
    context 'when all preconditions are met and sync executes' do
      before do
        stub_sync_enabled(true)
        application.update!(enabled: true)
      end

      context 'when group links exist in hierarchies which the user should not be a member of' do
        before do
          stub_microsoft_groups([dept_users]) # dept_users group link is in group1 / subgroup1 hierarchy
        end

        # User should be a member of group1 and subgroup1, but not group2. Still, sync should be
        # executed for group2 to ensure user is removed if they were previously a member.
        # Sync service is not called for group3 because no group links exist.
        it 'calls the service for all top-level groups with any groups links in the hierarchy' do
          expect(Groups::SyncService).to receive(:new).with(
            group1, user_with_identity, group_links: [subgroup1_link], manage_group_ids: [group1.id, subgroup1.id]
          ).and_call_original

          expect(Groups::SyncService).to receive(:new).with(
            group2, user_with_identity, group_links: [], manage_group_ids: [group2.id]
          ).and_call_original

          expect(Groups::SyncService).not_to receive(:new).with(group3, any_args)

          worker.perform(user_with_identity.id)
        end
      end

      context 'with a group in the hierarchy that has no group links' do
        let(:subgroup_without_links) { create(:group, parent: group2) }

        before do
          stub_microsoft_groups([dept_users])
        end

        it 'is not included in manage_group_ids' do
          expect(Groups::SyncService).to receive(:new).with(
            group1, user_with_identity, group_links: [subgroup1_link], manage_group_ids: [group1.id, subgroup1.id]
          ).and_call_original

          expect(Groups::SyncService).to receive(:new).with(
            group2, user_with_identity, group_links: [], manage_group_ids: [group2.id]
          ).and_call_original

          worker.perform(user_with_identity.id)
        end
      end
    end

    def stub_sync_enabled(enabled)
      allow_next_instance_of(::Gitlab::Auth::Saml::Config) do |instance|
        allow(instance).to receive(:microsoft_group_sync_enabled?).and_return(enabled)
      end
    end

    def stub_microsoft_groups(groups)
      allow_next_instance_of(::Microsoft::GraphClient) do |instance|
        allow(instance).to receive_messages(user_group_membership_object_ids: groups)
      end
    end
  end
end
