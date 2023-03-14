# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Oidc::AuthHash, feature_category: :system_access do
  let(:user_groups) { nil }
  let(:raw_info) { { groups: user_groups } }
  let(:omniauth_auth_hash) do
    OmniAuth::AuthHash.new(
      uid: 'my-uid',
      provider: 'openid_connect',
      extra: { raw_info: raw_info })
  end

  before do
    allow_next_instance_of(Gitlab::Auth::Oidc::Config) do |config|
      allow(config).to receive_messages({ groups_attribute: 'groups' })
    end
  end

  describe '#groups' do
    subject(:auth_hash_groups) { described_class.new(omniauth_auth_hash).groups }

    context 'when defined in the auth hash' do
      let(:user_groups) { %w[Cats Owls] }

      it 'returns the value' do
        expect(auth_hash_groups).to match_array(user_groups)
      end
    end

    context 'when empty' do
      it 'returns empty array' do
        expect(auth_hash_groups).to match_array([])
      end
    end

    context 'when undefined' do
      let(:raw_info) { {} }

      it 'returns empty array' do
        expect(auth_hash_groups).to match_array([])
      end
    end
  end
end
