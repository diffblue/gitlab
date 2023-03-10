# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Geo::Oauth::LogoutToken, feature_category: :geo_replication do
  let(:user) { create(:user) }
  let(:node) { create(:geo_node) }
  let(:access_token) { create(:doorkeeper_access_token, resource_owner_id: user.id, application_id: node.oauth_application_id) }
  let(:return_to) { '/project/test' }
  let(:state) { Gitlab::Geo::Oauth::LogoutState.new(token: access_token.token, return_to: return_to).encode }

  describe '#valid?' do
    it 'returns false when current user is nil' do
      token = described_class.new(nil, state)

      expect(token).not_to be_valid
      expect(token.errors.full_messages).to include('Current user could not be found')
    end

    it 'returns false when state is nil' do
      token = described_class.new(user, nil)

      expect(token).not_to be_valid
      expect(token.errors.full_messages).to include('Token could not be found')
    end

    it 'returns false when state is empty' do
      token = described_class.new(user, '')

      expect(token).not_to be_valid
      expect(token.errors.full_messages).to include('Token could not be found')
    end

    it 'returns false when token has an incorrect encoding' do
      allow_next_instance_of(Gitlab::Geo::Oauth::LogoutState) do |instance|
        allow(instance).to receive(:decode).and_return("\xD800\xD801\xD802")
      end

      token = described_class.new(user, state)

      expect(token).not_to be_valid
      expect(token.errors.full_messages).to include('Token could not be found')
    end

    it 'returns false when token could not be found' do
      allow(Doorkeeper::AccessToken)
        .to receive(:by_token)
        .and_return(nil)

      token = described_class.new(user, state)

      expect(token).not_to be_valid
      expect(token.errors.full_messages).to include('Token could not be found')
    end

    it 'returns false when token has an invalid status' do
      allow(Doorkeeper::AccessToken)
        .to receive(:by_token)
        .and_return(double(resource_owner_id: user.id, expired?: true))

      token = described_class.new(user, state)

      expect(token).not_to be_valid
      expect(token.errors.full_messages).to include('Token has expired')
    end

    it 'returns false when token does not belong to the user' do
      allow(Doorkeeper::AccessToken)
        .to receive(:by_token)
        .and_return(double(resource_owner_id: user.id, expired?: true))

      token = described_class.new(create(:user), state)

      expect(token).not_to be_valid
      expect(token.errors.full_messages).to include('User could not be found')
    end

    it 'returns true when token is valid' do
      token = described_class.new(user, state)

      expect(token).to be_valid
    end
  end

  describe '#return_to' do
    it 'returns nil when token is invalid' do
      token = described_class.new(user, nil)

      expect(token.return_to).to be_nil
    end

    it 'returns nil when there is no Geo node associated with the OAuth application' do
      allow(GeoNode)
        .to receive(:find_by_oauth_application_id)
        .with(node.oauth_application_id)
        .and_return(nil)

      token = described_class.new(user, state)

      expect(token.return_to).to be_nil
    end

    context 'when state return_to param is nil' do
      it 'returns the Geo node URL associated with the OAuth application' do
        state = Gitlab::Geo::Oauth::LogoutState.new(token: access_token.token, return_to: nil).encode
        token = described_class.new(user, state)

        expect(token.return_to).to eq(node.url)
      end
    end

    context 'when state return_to param is empty' do
      it 'returns the Geo node URL associated with the OAuth application' do
        state = Gitlab::Geo::Oauth::LogoutState.new(token: access_token.token, return_to: '').encode
        token = described_class.new(user, state)

        expect(token.return_to).to eq(node.url)
      end
    end

    context 'when state return_to param is set' do
      let(:return_to_url) { "#{node.url.chomp('/')}/project/test" }

      it 'returns the full path to the Geo node URL associated with the OAuth application' do
        token = described_class.new(user, state)

        expect(token.return_to).to eq(return_to_url)
      end

      it 'replaces the host with the Geo node associated with the OAuth application' do
        fake_return_to = 'http://fake-secondary/project/test'
        state = Gitlab::Geo::Oauth::LogoutState.new(token: access_token.token, return_to: fake_return_to).encode
        token = described_class.new(user, state)

        expect(token.return_to).to eq(return_to_url)
      end

      it 'handles leading and trailing slashes correctly' do
        return_to = '//project/test'
        state = Gitlab::Geo::Oauth::LogoutState.new(token: access_token.token, return_to: return_to).encode
        token = described_class.new(user, state)

        expect(token.return_to).to eq(return_to_url)
      end
    end
  end
end
