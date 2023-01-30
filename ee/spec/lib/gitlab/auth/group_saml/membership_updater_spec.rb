# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::GroupSaml::MembershipUpdater do
  let(:user) { create(:user) }
  let(:saml_provider) { create(:saml_provider, default_membership_role: Gitlab::Access::DEVELOPER) }
  let(:group) { saml_provider.group }
  let(:auth_hash) do
    Gitlab::Auth::GroupSaml::AuthHash.new(
      OmniAuth::AuthHash.new(extra: {
        raw_info: OneLogin::RubySaml::Attributes.new('groups' => %w(Developers Owners))
      })
    )
  end

  subject(:update_membership) { described_class.new(user, saml_provider, auth_hash).execute }

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

  it 'does not enqueue group sync' do
    expect(GroupSamlGroupSyncWorker).not_to receive(:perform_async)

    update_membership
  end

  context 'when SAML group links exist' do
    def stub_saml_group_sync_available(enabled)
      allow(group).to receive(:saml_group_sync_available?).and_return(enabled)
    end

    let!(:group_link) { create(:saml_group_link, saml_group_name: 'Owners', group: group) }
    let!(:subgroup_link) { create(:saml_group_link, saml_group_name: 'Developers', group: create(:group, parent: group)) }

    context 'when group sync is not available' do
      before do
        stub_saml_group_sync_available(false)
      end

      it 'does not enqueue group sync' do
        expect(GroupSamlGroupSyncWorker).not_to receive(:perform_async)

        update_membership
      end
    end

    context 'when group sync is available' do
      before do
        stub_saml_group_sync_available(true)
      end

      it 'enqueues group sync' do
        expect(GroupSamlGroupSyncWorker).to receive(:perform_async).with(user.id, group.id, match_array([group_link.id, subgroup_link.id]))

        update_membership
      end

      context 'with a group link outside the top-level group' do
        before do
          create(:saml_group_link, saml_group_name: 'Developers', group: create(:group))
        end

        it 'enqueues group sync without the outside group' do
          expect(GroupSamlGroupSyncWorker).to receive(:perform_async).with(user.id, group.id, match_array([group_link.id, subgroup_link.id]))

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
end
