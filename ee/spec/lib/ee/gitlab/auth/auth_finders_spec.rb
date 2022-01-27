# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::Gitlab::Auth::AuthFinders do
  include described_class
  include ::EE::GeoHelpers

  let(:current_request) { ActionDispatch::Request.new(env) }
  let(:env) do
    {
      'rack.input' => ''
    }
  end

  let_it_be(:user) { create(:user) }

  describe '#find_user_from_geo_token' do
    subject { find_user_from_geo_token }

    let_it_be(:primary) { create(:geo_node, :primary) }

    let(:path) { '/api/v4/geo/graphql' }
    let(:authorization_header) do
      ::Gitlab::Geo::JsonRequest
        .new(scope: ::Gitlab::Geo::API_SCOPE, authenticating_user_id: user.id)
        .headers['Authorization']
    end

    before do
      stub_current_geo_node(primary)

      env['SCRIPT_NAME'] = path
      current_request.headers['Authorization'] = authorization_header
    end

    it { is_expected.to eq(user) }

    context 'when the path is not Geo specific' do
      let(:path) { '/api/v4/test' }

      it { is_expected.to eq(nil) }
    end

    context 'when the Authorization header is invalid' do
      let(:authorization_header) { 'invalid' }

      it { is_expected.to eq(nil) }
    end

    context 'when the Authorization header is nil' do
      let(:authorization_header) { '' }

      it { is_expected.to eq(nil) }
    end

    context 'when the Authorization header is a Geo header' do
      it 'does not authenticate when the token expired' do
        travel_to(2.minutes.from_now) { expect { subject }.to raise_error(::Gitlab::Auth::UnauthorizedError) }
      end

      it 'does not authenticate when clocks are not in sync' do
        travel_to(2.minutes.ago) { expect { subject }.to raise_error(::Gitlab::Auth::UnauthorizedError) }
      end

      it 'does not authenticate with invalid decryption key error' do
        allow_next_instance_of(::Gitlab::Geo::JwtRequestDecoder) do |instance|
          expect(instance).to receive(:decode_auth_header).and_raise(Gitlab::Geo::InvalidDecryptionKeyError)
        end

        expect { subject }.to raise_error(::Gitlab::Auth::UnauthorizedError)
      end

      context 'when the scope is not API' do
        let(:authorization_header) do
          ::Gitlab::Geo::JsonRequest
            .new(scope: 'invalid', authenticating_user_id: user.id)
            .headers['Authorization']
        end

        it 'does not authenticate' do
          expect { subject }.to raise_error(::Gitlab::Auth::UnauthorizedError)
        end
      end

      context 'when it does not contain a user id' do
        let(:authorization_header) do
          ::Gitlab::Geo::JsonRequest
            .new(scope: ::Gitlab::Geo::API_SCOPE)
            .headers['Authorization']
        end

        it 'raises an unauthorize error' do
          expect { subject }.to raise_error(::Gitlab::Auth::UnauthorizedError)
        end
      end
    end

    context 'when the user does not exist' do
      let(:user) { create(:user) }

      it 'raises an unauthorized error' do
        user.delete

        expect { subject }.to raise_error(::Gitlab::Auth::UnauthorizedError)
      end
    end

    context 'when the geo_token_user_authentication feature flag is disabled' do
      before do
        stub_feature_flags(geo_token_user_authentication: false)
      end

      it 'returns immediately' do
        expect(::Gitlab::Geo::JwtRequestDecoder).not_to receive(:geo_auth_attempt?)
        expect(::Gitlab::Geo::JwtRequestDecoder).not_to receive(:new)
        expect(subject).to be_nil
      end
    end
  end
end
