# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupSaml::GroupManagedAccounts::CleanUpMembersService, feature_category: :system_access do
  subject(:service) { described_class.new(current_user, group) }

  let(:group) { Group.new }
  let(:current_user) { instance_double('User') }
  let(:destroy_member_service_spy) { spy('Members::DestroyService') }
  let(:destroy_identity_service_spy) { spy('GroupSaml::Identity::DestroyService') }

  let(:group_member_membership) { instance_double('Member', destroyed?: true) }
  let(:not_managed_identity) { instance_double('Identity', destroyed?: true, user: nil) }

  before do
    allow(Members::DestroyService).to receive(:new).with(current_user).and_return(destroy_member_service_spy)
    allow(GroupSaml::Identity::DestroyService)
      .to receive(:new).with(not_managed_identity).and_return(destroy_identity_service_spy)
    allow(GroupMembersFinder)
      .to receive(:new).with(group)
            .and_return(instance_double('GroupMembersFinder', not_managed: [group_member_membership]))
    allow(GroupSamlIdentityFinder)
      .to receive(:not_managed_identities).with(group: group).and_return([not_managed_identity])
  end

  it 'removes non-owner members without dedicated accounts from the group' do
    service.execute

    expect(destroy_member_service_spy).to have_received(:execute).with(group_member_membership)
  end

  it 'returns true' do
    expect(service.execute).to eq true
  end

  context 'when at least one non-owner member was not removed' do
    before do
      allow(group_member_membership).to receive(:destroyed?).and_return(false)
    end

    it 'returns false' do
      expect(service.execute).to eq false
    end
  end

  it 'unlinks identities for accounts not managed by given group' do
    service.execute

    expect(destroy_identity_service_spy).to have_received(:execute)
  end

  context 'for last group owner identity' do
    it 'does not remove the identity' do
      allow(group).to receive(:has_owner?).with(not_managed_identity.user).and_return true

      service.execute

      expect(destroy_identity_service_spy).not_to have_received(:execute)
    end
  end
end
