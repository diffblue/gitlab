# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupSaml::GroupManagedAccounts::TransferMembershipService, feature_category: :system_access do
  subject(:service) { described_class.new(current_user, group, session) }

  let(:group) { create(:group) }
  let(:current_user) { create(:user) }
  let(:oauth_data) { OmniAuth::AuthHash.new(info: { email: current_user.email }) }
  let(:session) { { 'oauth_data' => oauth_data } }

  before do
    stub_feature_flags(convert_user_to_group_managed_accounts: true, remove_non_gma_memberships: false)

    allow(Gitlab::Auth::GroupSaml::IdentityLinker)
      .to receive(:new).with(current_user, oauth_data, session, group.saml_provider)
            .and_return(instance_double('Gitlab::Auth::GroupSaml::IdentityLinker', link: '', failed?: false))
  end

  it 'removes the current password' do
    expect { service.execute }.to change { current_user.encrypted_password }.to('')
  end

  it 'returns true' do
    expect(service.execute).to eq true
  end

  it 'does not reduce the amount of memberships' do
    create(:project_member, :developer, user: current_user)
    create(:group_member, :developer, user: current_user)

    expect { service.execute }.not_to change { current_user.members.count }
  end

  context 'when remove_non_gma_memberships flag is enable' do
    before do
      stub_feature_flags(remove_non_gma_memberships: true)
    end

    it 'reduces the amount of memberships' do
      create(:project_member, :developer, user: current_user)
      create(:group_member, :developer, user: current_user)

      expect { service.execute }.to change { current_user.members.count }.by(-2)
    end

    context 'when at least one non-owner member was not removed' do
      before do
        member = create(:group_member, :developer, user: current_user)
        allow_next_instance_of(Members::DestroyService) do |service|
          allow(service).to receive(:execute).with(member).and_return(member)
        end
      end

      it 'returns a falsy value' do
        expect(service.execute).to be_falsy
      end
    end

    context 'when the user changes are not saved' do
      before do
        allow(current_user).to receive(:save).and_return(false)
      end

      it "doesn't remove account's members" do
        create(:group_member, :developer, user: current_user)

        expect { service.execute }.not_to change { current_user.members.count }
      end
    end

    context 'when the user is owner of a group' do
      it 'does not reduce the amount of memberships' do
        other_group = create(:group)
        other_group.add_owner(current_user)

        expect { service.execute }.not_to change { current_user.members.count }
      end
    end
  end

  context 'when the user changes are not saved' do
    before do
      allow(current_user).to receive(:save).and_return(false)
    end

    it "doesn't remove account's identities" do
      create(:identity, user: current_user)

      expect { service.execute }.not_to change { current_user.identities.count }
    end
  end

  it 'removes previous known identities of the account' do
    create(:identity, user: current_user)

    expect { service.execute }.to change { current_user.identities.count }.from(1).to(0)
  end

  context "when the email doesn't match" do
    let(:oauth_data) { OmniAuth::AuthHash.new(info: { email: 'new@email.com' }) }

    it 'returns a falsy value' do
      expect(service.execute).to be_falsy
    end
  end

  context 'convert_user_to_group_managed_accounts flag is disable' do
    before do
      stub_feature_flags(convert_user_to_group_managed_accounts: false)
    end

    it 'returns a falsy value' do
      expect(service.execute).to be_falsy
    end

    it "doesn't remove non-owner members without dedicated accounts from the group" do
      expect { service.execute }.not_to change { current_user.members.count }
    end
  end

  context 'transferred account' do
    before do
      service.execute
    end

    it "doesn't allow blank passwords" do
      expect(current_user.valid_password?('')).to be false
      expect(current_user.valid_password?(nil)).to be false
      expect(current_user.valid_password?(' ')).to be false
    end
  end
end
