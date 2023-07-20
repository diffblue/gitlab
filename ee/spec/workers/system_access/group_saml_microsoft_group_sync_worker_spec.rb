# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemAccess::GroupSamlMicrosoftGroupSyncWorker, :aggregate_failures, feature_category: :system_access do
  include ::SystemAccess::GroupSyncHelpers

  describe '#perform' do
    let(:worker) { described_class.new }
    let_it_be(:user) { create(:user) }

    let_it_be(:top_level_group) { create(:group) }
    let_it_be(:top_level_group_link_access_level) { Gitlab::Access::REPORTER }
    let_it_be(:top_level_group_link) do
      create(:saml_group_link,
        group: top_level_group,
        saml_group_name: 'Org Users',
        access_level: top_level_group_link_access_level
      )
    end

    let_it_be(:group) { create(:group, parent: top_level_group) }
    let_it_be(:group_link_access_level) { Gitlab::Access::DEVELOPER }
    let_it_be(:group_link) do
      create(:saml_group_link,
        group: group,
        saml_group_name: 'Dept Users',
        access_level: group_link_access_level
      )
    end

    let_it_be(:saml_provider) do
      create(:saml_provider, group: top_level_group, enabled: true, default_membership_role: Gitlab::Access::GUEST)
    end

    let_it_be(:application) do
      create(:system_access_microsoft_application, namespace: top_level_group)
    end

    shared_examples 'sync unavailable' do
      it 'does not call the sync service' do
        expect(Groups::SyncService).not_to receive(:new)

        perform
      end
    end

    context 'when group SAML is not enabled' do
      before do
        saml_provider.update!(enabled: false)

        # Satisfy all other conditions for a sync to run
        application.update!(enabled: true)
        stub_licensed_features(microsoft_group_sync: true)
        create(:group_saml_identity, user: user, saml_provider: saml_provider)
        stub_microsoft_groups(['Org Users', 'Dept Users'])
      end

      it_behaves_like 'sync unavailable'
    end

    context 'when group SAML is enabled' do
      before do
        saml_provider.update!(enabled: true)
      end

      it_behaves_like 'sync unavailable'

      context 'when microsoft_group_sync feature is not licensed' do
        before do
          stub_licensed_features(microsoft_group_sync: false)

          # Satisfy all other conditions for a sync to run
          application.update!(enabled: true)
          create(:group_saml_identity, user: user, saml_provider: saml_provider)
          stub_microsoft_groups(['Org Users', 'Dept Users'])
        end

        it_behaves_like 'sync unavailable'
      end

      context 'when microsoft_group_sync feature is licensed' do
        before do
          stub_licensed_features(microsoft_group_sync: true)
        end

        it_behaves_like 'sync unavailable'

        context 'when the Microsoft application is not enabled' do
          before do
            application.update!(enabled: false)

            # Satisfy all other conditions for a sync to run
            create(:group_saml_identity, user: user, saml_provider: saml_provider)
            stub_microsoft_groups(['Org Users', 'Dept Users'])
          end

          it_behaves_like 'sync unavailable'
        end

        context 'when the Microsoft application is enabled' do
          before do
            create(:system_access_microsoft_graph_access_token, system_access_microsoft_application: application)
            application.update!(enabled: true)
          end

          it_behaves_like 'sync unavailable'

          context 'when the user has a SAML identity' do
            before do
              create(:group_saml_identity, user: user, saml_provider: saml_provider)
            end

            context 'when the Microsoft API returns no groups' do
              before do
                stub_microsoft_groups([])
              end

              it_behaves_like 'sync unavailable'
            end

            context 'when no group links match' do
              before do
                stub_microsoft_groups(['Other Users'])
              end

              it_behaves_like 'sync unavailable'
            end

            context 'when group links match' do
              before do
                stub_microsoft_groups(['Org Users', 'Dept Users'])
              end

              it 'adds the users as members' do
                expect_sync_service_call(
                  group_links: [top_level_group_link, group_link],
                  manage_group_ids: [top_level_group.id, group.id]
                )
                expect_metadata_logging_call({ added: 2, updated: 0, removed: 0 })

                perform

                expect(top_level_member_access_level).to eq(top_level_group_link_access_level)
                expect(group_member_access_level).to eq(group_link_access_level)
              end
            end

            context 'for SAML provider default_membership_role behavior' do
              context 'when matching group links do not include the top-level group' do
                before do
                  stub_microsoft_groups(['Dept Users'])
                end

                it 'adds the member to the subgroup and retains the top-level group default membership role' do
                  top_level_group.add_member(user, saml_provider.default_membership_role)

                  expect_sync_service_call(group_links: [group_link], manage_group_ids: [group.id])
                  expect_metadata_logging_call({ added: 1, updated: 0, removed: 0 })

                  perform

                  expect(top_level_member_access_level)
                    .to eq(top_level_group.saml_provider.default_membership_role)
                end

                context 'when the member is the last owner' do
                  before do
                    top_level_group.add_member(user, Gitlab::Access::OWNER)
                  end

                  it 'does not change the access level to the default membership role' do
                    expect_metadata_logging_call({ added: 0, updated: 0, removed: 0 })

                    perform

                    expect(top_level_member_access_level).to eq(Gitlab::Access::OWNER)
                  end
                end

                context 'when the access level does not match the default membership role' do
                  let_it_be(:existing_access_level) { Gitlab::Access::MAINTAINER }

                  before do
                    top_level_group.add_member(user, existing_access_level)
                  end

                  it 'reverts to the default membership role' do
                    expect_metadata_logging_call({ added: 0, updated: 1, removed: 0 })

                    perform

                    expect(top_level_member_access_level)
                      .to eq(top_level_group.saml_provider.default_membership_role)
                  end

                  it 'does not update the access level when the top level group has no group links' do
                    top_level_group_link.destroy!

                    expect_sync_service_call(group_links: [group_link], manage_group_ids: [group.id])
                    expect_metadata_logging_call({ added: 0, updated: 0, removed: 0 })

                    perform

                    expect(top_level_member_access_level).to eq(existing_access_level)
                  end
                end

                it 'does not touch the member record when the access level matches the default membership role' do
                  top_level_group.add_member(user, top_level_group.saml_provider.default_membership_role)
                  updated_at = top_level_group.members.find_by(user_id: user.id).updated_at

                  expect_metadata_logging_call({ added: 1, updated: 0, removed: 0 })

                  # Use arbitrary future time to test whether worker touches the member record
                  travel_to(5.minutes.from_now) do
                    perform
                  end

                  expect(top_level_group.members.find_by(user_id: user.id).updated_at).to eq(updated_at)
                  expect(top_level_member_access_level)
                    .to eq(top_level_group.saml_provider.default_membership_role)
                end
              end
            end
          end
        end
      end
    end

    def perform
      worker.perform(user.id, top_level_group.id)
    end

    def top_level_member_access_level
      top_level_group.members.find_by(user_id: user.id).access_level
    end

    def group_member_access_level
      group.members.find_by(user_id: user.id).access_level
    end

    def stub_microsoft_groups(groups)
      allow_next_instance_of(::Microsoft::GraphClient) do |instance|
        allow(instance).to receive_messages(user_group_membership_object_ids: groups)
      end
    end
  end
end
