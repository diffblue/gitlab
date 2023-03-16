# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Auth::SamlGroupSyncWorker, feature_category: :system_access do
  describe '#perform' do
    let_it_be(:user) { create(:user) }

    let_it_be(:top_level_group1) { create(:group) }
    let_it_be(:top_level_group_link1) { create(:saml_group_link, group: top_level_group1) }

    let_it_be(:group1_subgroup) { create(:group, parent: top_level_group1) }
    let_it_be(:group1_subgroup_group_link) { create(:saml_group_link, group: group1_subgroup) }

    let(:worker) { described_class.new }

    context 'when saml_group_sync feature is not licensed' do
      it 'does not call the sync service' do
        expect(Groups::SyncService).not_to receive(:new)

        perform([top_level_group_link1.id])
      end
    end

    context 'when the saml_group_sync feature is licensed' do
      before do
        stub_licensed_features(saml_group_sync: true)
      end

      context 'when SAML is not enabled' do
        it 'does not call the sync service' do
          expect(Groups::SyncService).not_to receive(:new)

          perform([top_level_group_link1.id])
        end
      end

      context 'when SAML is enabled' do
        before do
          stub_saml_group_sync_enabled(true)
        end

        it 'calls the sync service with the group links' do
          expect_sync_service_call(group_links: [top_level_group_link1, group1_subgroup_group_link])

          perform([top_level_group_link1.id, group1_subgroup_group_link.id])
        end

        it 'does not call the sync service when the user does not exist' do
          expect(Groups::SyncService).not_to receive(:new)

          described_class.new.perform(non_existing_record_id, [group1_subgroup_group_link])
        end

        context 'when group links exist in hierarchies which the user should not be a member of' do
          let_it_be(:top_level_group2) { create(:group) }
          let_it_be(:top_level_group_link2) { create(:saml_group_link, group: top_level_group2) }

          it 'calls the service for top level groups with links that the user should not be a member of' do
            expect_sync_service_call(
              group_links: [top_level_group_link1],
              manage_group_ids: [top_level_group1.id, group1_subgroup.id]
            )
            expect_sync_service_call(
              group_links: [],
              manage_group_ids: [top_level_group2.id],
              top_level_group: top_level_group2
            )

            perform([top_level_group_link1.id])
          end
        end

        context 'with a group in the hierarchy that has no group links' do
          let(:group_without_links) { create(:group, parent: top_level_group1) }

          it 'is not included in manage_group_ids' do
            expect_sync_service_call(group_links: [top_level_group_link1, group1_subgroup_group_link])

            perform([top_level_group_link1.id, group1_subgroup_group_link.id])
          end
        end

        context 'when the worker receives no group link ids' do
          it 'calls the sync service' do
            expect_sync_service_call(group_links: [])

            perform([])
          end
        end
      end
    end

    def expect_sync_service_call(group_links:, manage_group_ids: nil, top_level_group: top_level_group1)
      manage_group_ids = [top_level_group1.id, group1_subgroup.id] if manage_group_ids.nil?

      expect(Groups::SyncService).to receive(:new).with(
        top_level_group, user, group_links: group_links, manage_group_ids: manage_group_ids
      ).and_call_original
    end

    def perform(group_links)
      worker.perform(user.id, group_links)
    end

    def stub_saml_group_sync_enabled(enabled)
      allow(::Gitlab::Auth::Saml::Config).to receive(:group_sync_enabled?).and_return(enabled)
    end
  end
end
