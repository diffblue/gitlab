# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::API::Entities::IdentityDetail do
  describe 'exposes extern_uid and user_id fields' do
    let(:user) { create(:user) }
    let!(:identity) { create(:group_saml_identity, user: user) }
    let(:identity_detail_entity) { described_class.new(identity) }

    subject(:entity) { identity_detail_entity.as_json }

    it 'exposes the attributes' do
      expect(entity[:extern_uid]).to eq identity.extern_uid
      expect(entity[:user_id]).to eq identity.user_id
    end
  end
end
