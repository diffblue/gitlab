# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupSamlGroupSyncWorker, feature_category: :system_access do
  describe '#perform' do
    let_it_be(:user) { create(:user) }

    let_it_be(:top_level_group) { create(:group) }
    let_it_be(:top_level_group_link) do
      create(:saml_group_link, group: top_level_group, access_level: Gitlab::Access::DEVELOPER)
    end

    let_it_be(:group) { create(:group, parent: top_level_group) }
    let_it_be(:group_link) do
      create(:saml_group_link, group: group, access_level: Gitlab::Access::DEVELOPER)
    end

    let(:worker) { described_class.new }

    context 'when the group does not have group_saml_group_sync feature licensed' do
      before do
        create(:saml_provider, group: top_level_group, enabled: true)
      end

      it 'does not call the sync service' do
        expect(Groups::SyncService).not_to receive(:new)

        perform([top_level_group_link.id])
      end
    end

    context 'when the group has group_saml_group_sync feature licensed' do
      before do
        stub_licensed_features(saml_group_sync: true)
      end

      context 'when SAML is not enabled' do
        it 'does not call the sync service' do
          expect(Groups::SyncService).not_to receive(:new)

          perform([top_level_group_link.id])
        end
      end

      context 'when SAML is enabled' do
        let_it_be(:saml_provider) do
          create(:saml_provider, group: top_level_group, enabled: true, default_membership_role: Gitlab::Access::GUEST)
        end

        subject(:top_level_member_access_level) do
          top_level_group.members.find_by(user_id: user.id).access_level
        end

        context 'default membership' do
          context 'when group link ids do not include the top level group' do
            it 'does not pass the top level group to the sync service as group to manage' do
              top_level_group.add_member(user, saml_provider.default_membership_role)

              expect_sync_service_call(group_links: [group_link], manage_group_ids: [group.id])

              perform([group_link.id])
            end

            it 'retains user default membership role' do
              perform([group_link.id])

              expect(top_level_member_access_level)
                .to eq(top_level_group.saml_provider.default_membership_role)
            end

            context 'when the member is the last owner' do
              before do
                top_level_group.add_member(user, Gitlab::Access::OWNER)
              end

              it 'does not update the member when the member is the last owner' do
                expect_metadata_logging_call({ added: 0, updated: 0, removed: 0 })

                perform([group_link.id])

                expect(top_level_member_access_level)
                  .to eq(Gitlab::Access::OWNER)
              end
            end

            context 'when the membership role deviates from the default' do
              before do
                top_level_group.add_member(user, Gitlab::Access::MAINTAINER)
              end

              it 'reverts to the default membership role' do
                expect_metadata_logging_call({ added: 0, updated: 1, removed: 0 })

                perform([group_link.id])

                expect(top_level_member_access_level)
                  .to eq(top_level_group.saml_provider.default_membership_role)
              end

              it 'does not update the default membership when the top level group has no group links' do
                top_level_group_link.destroy!

                expect_sync_service_call(group_links: [group_link], manage_group_ids: [group.id])
                expect_metadata_logging_call({ added: 0, updated: 0, removed: 0 })

                perform([group_link.id])

                expect(top_level_member_access_level).to eq(Gitlab::Access::MAINTAINER)
              end
            end

            it 'does not update the membership role when it does not deviate from the default' do
              top_level_group.add_member(user, top_level_group.saml_provider.default_membership_role)

              expect_metadata_logging_call({ added: 1, updated: 0, removed: 0 })
              expect(top_level_group).not_to receive(:add_user)

              perform([group_link.id])

              expect(top_level_member_access_level)
                .to eq(top_level_group.saml_provider.default_membership_role)
            end
          end

          context 'when group link ids include the top level group' do
            it 'does not revert to the default membership role' do
              perform([top_level_group_link.id])

              expect(top_level_member_access_level).to eq(Gitlab::Access::DEVELOPER)
            end
          end
        end

        it 'calls the sync service with the group links' do
          expect_sync_service_call(group_links: [top_level_group_link, group_link])
          expect_metadata_logging_call({ added: 2, updated: 0, removed: 0 })

          perform([top_level_group_link.id, group_link.id])
        end

        it 'does not call the sync service when the user does not exist' do
          expect(Groups::SyncService).not_to receive(:new)

          described_class.new.perform(non_existing_record_id, top_level_group.id, [group_link])
        end

        it 'includes groups with links in manage_group_ids' do
          expect_sync_service_call(
            group_links: [top_level_group_link],
            manage_group_ids: [top_level_group.id, group.id]
          )

          perform([top_level_group_link.id])
        end

        context 'when a group link falls outside the top-level group' do
          let(:outside_group_link) { create(:saml_group_link, group: create(:group)) }

          it 'drops group links outside the top level group' do
            expect_sync_service_call(group_links: [top_level_group_link, group_link])
            expect_metadata_logging_call({ added: 2, updated: 0, removed: 0 })

            perform([outside_group_link.id, top_level_group_link.id, group_link.id])
          end
        end

        context 'with a group in the hierarchy that has no group links' do
          let(:group_without_links) { create(:group, parent: group) }

          it 'is not included in manage_group_ids' do
            expect_sync_service_call(group_links: [top_level_group_link, group_link])
            expect_metadata_logging_call({ added: 2, updated: 0, removed: 0 })

            perform([top_level_group_link.id, group_link.id])
          end
        end

        context 'when the worker receives no group link ids' do
          before do
            group.add_member(user, Gitlab::Access::MAINTAINER)
          end

          it 'calls the sync service, updates default membership and removes existing users' do
            expect_sync_service_call(group_links: [], manage_group_ids: [group.id])
            expect_metadata_logging_call({ added: 0, updated: 1, removed: 1 })

            perform([])

            expect(top_level_member_access_level).to eq(Gitlab::Access::GUEST)
          end
        end
      end
    end

    def expect_sync_service_call(group_links:, manage_group_ids: nil)
      manage_group_ids = [top_level_group.id, group.id] if manage_group_ids.nil?

      expect(Groups::SyncService).to receive(:new).with(
        top_level_group, user, group_links: group_links, manage_group_ids: manage_group_ids
      ).and_call_original
    end

    def expect_metadata_logging_call(stats)
      expect(worker).to receive(:log_extra_metadata_on_done).with(:stats, stats)
    end

    def perform(group_links)
      worker.perform(user.id, top_level_group.id, group_links)
    end
  end
end
