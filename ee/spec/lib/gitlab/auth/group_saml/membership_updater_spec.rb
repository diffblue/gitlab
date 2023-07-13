# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::GroupSaml::MembershipUpdater, feature_category: :system_access do
  let(:user) { create(:user) }
  let(:saml_provider) { create(:saml_provider, default_membership_role: Gitlab::Access::DEVELOPER) }
  let(:group) { saml_provider.group }

  subject(:update_membership) { described_class.new(user, saml_provider, auth_hash).execute }

  shared_examples 'not enqueueing Microsoft Group Sync worker' do
    it 'does not enqueue Microsoft Group Sync worker' do
      expect(::SystemAccess::GroupSamlMicrosoftGroupSyncWorker).not_to receive(:perform_async)

      update_membership
    end
  end

  shared_examples 'not enqueueing Group SAML Group Sync worker' do
    it 'does not enqueue Microsoft Group Sync worker' do
      expect(GroupSamlGroupSyncWorker).not_to receive(:perform_async)

      update_membership
    end
  end

  context 'for default behavior' do
    let_it_be(:auth_hash) { {} }

    it 'adds the user to the group' do
      subject

      expect(group.users).to include(user)
    end

    it 'adds the member with the specified `default_membership_role`' do
      expect(group).to receive(:add_member).with(user, Gitlab::Access::DEVELOPER).and_call_original

      update_membership

      created_member = group.members.find_by(user: user)
      expect(created_member.access_level).to eq(Gitlab::Access::DEVELOPER)
    end

    it "doesn't duplicate group membership" do
      group.add_guest(user)

      subject

      expect(group.members.count).to eq 1
    end

    it "doesn't overwrite existing membership level" do
      group.add_maintainer(user)

      subject

      expect(group.members.pluck(:access_level)).to eq([Gitlab::Access::MAINTAINER])
    end

    it "logs an audit event" do
      expect do
        subject
      end.to change { AuditEvent.by_entity('Group', group).count }.by(1)

      expect(AuditEvent.last.details).to include(add: 'user_access', target_details: user.name, as: 'Developer')
    end

    it_behaves_like 'not enqueueing Group SAML Group Sync worker'
    it_behaves_like 'not enqueueing Microsoft Group Sync worker'
  end

  context 'when SAML group links exist' do
    let!(:group_link) { create(:saml_group_link, saml_group_name: 'Owners', group: group) }
    let!(:subgroup_link) { create(:saml_group_link, saml_group_name: 'Developers', group: create(:group, parent: group)) }

    context 'when the auth hash contains groups' do
      let_it_be(:auth_hash) do
        Gitlab::Auth::GroupSaml::AuthHash.new(
          OmniAuth::AuthHash.new(extra: {
            raw_info: OneLogin::RubySaml::Attributes.new('groups' => %w(Developers Owners))
          })
        )
      end

      context 'when group sync is not available' do
        before do
          stub_saml_group_sync_available(false)
        end

        it_behaves_like 'not enqueueing Group SAML Group Sync worker'
      end

      context 'when group sync is available' do
        before do
          stub_saml_group_sync_available(true)
        end

        it 'enqueues group sync' do
          expect(GroupSamlGroupSyncWorker)
            .to receive(:perform_async).with(user.id, group.id, match_array([group_link.id, subgroup_link.id]))

          update_membership
        end

        context 'with a group link outside the top-level group' do
          before do
            create(:saml_group_link, saml_group_name: 'Developers', group: create(:group))
          end

          it 'enqueues group sync without the outside group' do
            expect(GroupSamlGroupSyncWorker)
              .to receive(:perform_async).with(user.id, group.id, match_array([group_link.id, subgroup_link.id]))

            update_membership
          end
        end

        context 'when auth hash contains no groups' do
          let!(:auth_hash) do
            Gitlab::Auth::GroupSaml::AuthHash.new(
              OmniAuth::AuthHash.new(extra: { raw_info: OneLogin::RubySaml::Attributes.new })
            )
          end

          it 'enqueues group sync' do
            expect(GroupSamlGroupSyncWorker).to receive(:perform_async).with(user.id, group.id, [])

            update_membership
          end
        end

        context 'when auth hash groups do not match group links' do
          before do
            group_link.update!(saml_group_name: 'Web Developers')
            subgroup_link.destroy!
          end

          it 'enqueues group sync' do
            expect(GroupSamlGroupSyncWorker).to receive(:perform_async).with(user.id, group.id, [])

            update_membership
          end
        end
      end
    end

    context 'when the auth hash contains a Microsoft group claim' do
      let_it_be(:auth_hash) do
        Gitlab::Auth::GroupSaml::AuthHash.new(
          OmniAuth::AuthHash.new(extra: {
            raw_info: OneLogin::RubySaml::Attributes.new({
              'http://schemas.microsoft.com/claims/groups.link' =>
                ['https://graph.windows.net/8c750e43/users/e631c82c/getMemberObjects']
            })
          })
        )
      end

      context 'when Microsoft Group Sync is not licensed' do
        let!(:application) { create(:system_access_microsoft_application, enabled: true, namespace: group) }

        before do
          stub_feature_flags(microsoft_azure_group_sync: true)
          stub_saml_group_sync_available(true)
        end

        it_behaves_like 'not enqueueing Microsoft Group Sync worker'
      end

      context 'when Microsoft Group Sync is licensed' do
        before do
          stub_licensed_features(microsoft_group_sync: true)
        end

        it_behaves_like 'not enqueueing Microsoft Group Sync worker'

        context 'when SAML Group Sync is not available' do
          before do
            stub_saml_group_sync_available(false)
          end

          it_behaves_like 'not enqueueing Microsoft Group Sync worker'

          context 'when a Microsoft Application is present and enabled' do
            let!(:application) { create(:system_access_microsoft_application, enabled: true, namespace: group) }

            it_behaves_like 'not enqueueing Microsoft Group Sync worker'
          end
        end

        context 'when Group SAML Group Sync is enabled' do
          before do
            stub_saml_group_sync_available(true)
          end

          it_behaves_like 'not enqueueing Microsoft Group Sync worker'

          context 'when a Microsoft Application is present' do
            let!(:application) { create(:system_access_microsoft_application, namespace: group) }

            context 'when the Microsoft Application is not enabled' do
              before do
                application.update!(enabled: false)
              end

              it_behaves_like 'not enqueueing Microsoft Group Sync worker'
            end

            context 'when the Microsoft application is enabled' do
              before do
                application.update!(enabled: true)
              end

              it 'enqueues Microsoft Group Sync worker' do
                expect(::SystemAccess::GroupSamlMicrosoftGroupSyncWorker)
                  .to receive(:perform_async).with(user.id, group.id)

                update_membership
              end

              it_behaves_like 'not enqueueing Group SAML Group Sync worker'

              context 'when microsoft_azure_group_sync feature flag is not enabled' do
                before do
                  stub_feature_flags(microsoft_azure_group_sync: false)
                end

                it_behaves_like 'not enqueueing Microsoft Group Sync worker'
              end
            end
          end
        end
      end
    end

    # Microsoft should never send both, but it's important we're only running
    # one sync. This test serves to ensure we have that safeguard in place.
    context 'when the auth hash contains both groups and a group claim' do
      let_it_be(:auth_hash) do
        Gitlab::Auth::GroupSaml::AuthHash.new(
          OmniAuth::AuthHash.new(extra: {
            raw_info: OneLogin::RubySaml::Attributes.new({
              'groups' => %w(Developers Owners),
              'http://schemas.microsoft.com/claims/groups.link' =>
                ['https://graph.windows.net/8c750e43/users/e631c82c/getMemberObjects']
            })
          })
        )
      end

      let!(:application) { create(:system_access_microsoft_application, enabled: true, namespace: group) }

      before do
        stub_licensed_features(microsoft_group_sync: true)
        stub_saml_group_sync_available(true)
      end

      it 'enqueues Microsoft Group Sync worker' do
        expect(::SystemAccess::GroupSamlMicrosoftGroupSyncWorker)
          .to receive(:perform_async).with(user.id, group.id)

        update_membership
      end

      it_behaves_like 'not enqueueing Group SAML Group Sync worker'
    end
  end

  def stub_saml_group_sync_available(enabled)
    allow(group).to receive(:saml_group_sync_available?).and_return(enabled)
  end
end
