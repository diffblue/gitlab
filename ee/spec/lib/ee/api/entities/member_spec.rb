# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Member do
  subject(:entity_representation) { described_class.new(member).as_json }

  let(:member) { build_stubbed(:group_member) }
  let(:group_saml_identity) { build_stubbed(:group_saml_identity, extern_uid: 'TESTIDENTITY') }

  before do
    allow(member).to receive(:group_saml_identity).and_return(group_saml_identity)
  end

  context 'when current user is allowed to read group saml identity' do
    before do
      allow(Ability).to receive(:allowed?).with(anything, :read_group_saml_identity, member.source).and_return(true)
    end

    it 'exposes group_saml_identity' do
      expect(entity_representation[:group_saml_identity]).to include(extern_uid: 'TESTIDENTITY')
    end
  end

  context 'when current user is not allowed to read group saml identity' do
    before do
      allow(Ability).to receive(:allowed?).with(anything, :read_group_saml_identity, member.source).and_return(false)
    end

    it 'does not expose group saml identity' do
      expect(entity_representation.keys).not_to include(:group_saml_identity)
    end
  end

  context 'when current user is allowed to manage user' do
    before do
      allow(member.user).to receive(:managed_by?).and_return(true)
    end

    it 'exposes email' do
      expect(entity_representation.keys).to include(:email)
    end
  end

  context 'when current user is not allowed to manage user' do
    before do
      allow(member.user).to receive(:managed_by?).and_return(false)
    end

    it 'does not expose email' do
      expect(entity_representation.keys).not_to include(:email)
    end
  end

  context 'with state' do
    it 'exposes human_state_name as membership_state' do
      expect(entity_representation.keys).to include(:membership_state)
      expect(entity_representation[:membership_state]).to eq member.human_state_name
    end
  end

  context 'when the member is provisioned' do
    it 'does not include the user email address' do
      expect(entity_representation.keys).not_to include(:email)
    end

    context 'when the current user manages the provisioned user' do
      before do
        allow(member.user).to receive(:provisioned_by_group).and_return(true)
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?).with(anything, :admin_group_member, anything).and_return(true)
      end

      it 'includes the user email address' do
        expect(entity_representation[:email]).to eq(member.user.email)
      end
    end
  end

  context 'with member role' do
    let_it_be(:member_role) { create(:member_role) }

    it 'exposes member role' do
      allow(member).to receive(:member_role).and_return(member_role)

      expect(entity_representation[:member_role][:id]).to eq member_role.id
      expect(entity_representation[:member_role][:base_access_level]).to eq member_role.base_access_level
      expect(entity_representation[:member_role][:group_id]).to eq(member_role.namespace.id)
    end
  end

  context 'without member role' do
    it 'does not expose member role' do
      expect(entity_representation[:member_role]).to be_nil
    end
  end
end
