# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Geo::Oauth::Session, :geo, feature_category: :geo_replication do
  include EE::GeoHelpers

  # This spec doesn't work with a relative_url_root https://gitlab.com/gitlab-org/gitlab/issues/11261
  let!(:primary_node) { create(:geo_node, :primary, url: 'http://primary') }
  let(:secondary_node) { create(:geo_node) }
  let(:oauth_application) { secondary_node.oauth_application }
  let(:access_token) { create(:doorkeeper_access_token, application: oauth_application) }

  before do
    stub_current_geo_node(secondary_node)
  end

  describe '#authorized_url' do
    it 'returns a valid url to the primary node' do
      expect(subject.authorize_url).to start_with(primary_node.url)
    end

    context 'secondary is configured with relative URL' do
      def stub_relative_url(host, script_name)
        url_options = { host: host, protocol: "http", port: nil, script_name: script_name }

        allow(Rails.application.routes).to receive(:default_url_options).and_return(url_options)
      end

      it 'does not include secondary relative URL path' do
        secondary_url = 'http://secondary.host/relative-path/'

        stub_config_setting(url: secondary_url, https: false)
        stub_relative_url('secondary.host', '/relative-path')

        expect(subject.authorize_url).not_to include('relative-path')
      end
    end

    context 'primary is configured with a different internal URL' do
      it 'uses the external URL for the authorize redirect' do
        primary_node.update!(internal_url: 'http://internal-primary')

        expect(subject.authorize_url).not_to include('internal-primary')
        expect(subject.authorize_url).to start_with(primary_node.url)
      end
    end
  end

  describe '#authenticate' do
    let(:api_url) { "#{primary_node.internal_url.chomp('/')}/api/v4/user" }
    let(:user_json) { Gitlab::Json.dump({ id: 555, email: 'user@example.com' }.as_json) }

    context 'on success' do
      before do
        stub_request(:get, api_url).to_return(
          body: user_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      it 'returns hashed user data' do
        parsed_json = Gitlab::Json.parse(user_json)

        expect(subject.authenticate(access_token.token)).to eq(parsed_json)
      end
    end

    context 'on invalid token' do
      before do
        stub_request(:get, api_url).to_return(status: [401, 'Unauthorized'])
      end

      it 'raises exception' do
        expect { subject.authenticate(access_token.token) }.to raise_error(OAuth2::Error)
      end
    end

    context 'primary is configured with relative URL' do
      it 'includes primary relative URL path' do
        api_url = 'http://localhost/relative-path/'

        primary_node.update!(url: api_url)

        api_response = double(parsed: true)

        expect_next_instance_of(OAuth2::AccessToken) do |instance|
          expect(instance).to receive(:get).with(%r{^#{api_url}}).and_return(api_response)
        end

        subject.authenticate('any token')
      end
    end
  end

  describe '#get_token' do
    context 'primary is configured with relative URL' do
      it "makes the request to a primary's relative URL" do
        response = Gitlab::Json.dump({ access_token: 'fake-token' }.as_json)
        primary_node.update!(url: 'http://example.com/gitlab/')
        api_url = "#{primary_node.internal_url}oauth/token"

        stub_request(:post, api_url).to_return(
          body: response,
          headers: { 'Content-Type' => 'application/json' }
        )

        expect(subject.get_token('any code')).to eq('fake-token')
      end
    end
  end
end
