# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::AuthFinders do
  include described_class
  include ::EE::GeoHelpers

  let(:request) { ActionDispatch::Request.new(env) }
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
      request.headers['Authorization'] = authorization_header
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
          expect(instance).to receive(:decode).and_raise(Gitlab::Geo::InvalidDecryptionKeyError)
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
  end

  describe '#find_user_from_bearer_token' do
    context 'with a personal access token' do
      before do
        env[described_class::PRIVATE_TOKEN_HEADER] = create(:personal_access_token, user: user).token
      end

      it 'returns user' do
        expect(find_user_from_bearer_token).to eq user
      end

      context 'when personal access tokens are disabled' do
        before do
          stub_licensed_features(disable_personal_access_tokens: true)
          stub_application_setting(disable_personal_access_tokens: true)
        end

        it 'raises unauthorized error' do
          expect { find_user_from_bearer_token }.to raise_error(Gitlab::Auth::UnauthorizedError)
        end
      end
    end
  end

  describe '#find_user_from_access_token' do
    before do
      env[described_class::PRIVATE_TOKEN_HEADER] = create(:personal_access_token, user: user).token
    end

    context 'when validate_access_token! returns valid' do
      it 'returns user' do
        expect(find_user_from_access_token).to eq user
      end

      context 'when personal access tokens are disabled' do
        before do
          stub_licensed_features(disable_personal_access_tokens: true)
          stub_application_setting(disable_personal_access_tokens: true)
        end

        it 'raised unauthorized error' do
          expect { find_user_from_access_token }.to raise_error(Gitlab::Auth::UnauthorizedError)
        end
      end
    end
  end

  describe '#find_user_from_feed_token' do
    context 'when the request format is atom' do
      before do
        env['SCRIPT_NAME'] = 'url.atom'
        env['HTTP_ACCEPT'] = 'application/atom+xml'
      end

      context 'when feed_token param is provided' do
        context 'when the feed token is valid' do
          before do
            request.update_param(:feed_token, user.feed_token)
          end

          context 'when personal access tokens are disabled' do
            before do
              stub_application_setting(disable_personal_access_tokens: true)
            end

            it 'returns user' do
              expect(find_user_from_feed_token(:rss)).to eq user
            end

            context 'when disable_personal_access_tokens feature is licensed' do
              before do
                stub_licensed_features(disable_personal_access_tokens: true)
              end

              it 'returns nil' do
                expect(find_user_from_feed_token(:rss)).to be_nil
              end
            end
          end
        end
      end
    end
  end
end
