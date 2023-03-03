# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::GraphqlRequestService, :geo, feature_category: :geo_replication do
  include ::EE::GeoHelpers
  include ApiHelpers

  let_it_be(:primary)   { create(:geo_node, :primary) }
  let_it_be(:secondary) { create(:geo_node) }
  let_it_be(:user) { create(:user) }

  before do
    stub_current_geo_node(primary)
  end

  RSpec::Matchers.define :jwt_token_with_data do |data|
    match do |actual_headers|
      geo_jwt_decoder = ::Gitlab::Geo::JwtRequestDecoder.new(actual_headers['Authorization'])
      result = geo_jwt_decoder.decode

      expect(result).to eq(data)
    end
  end

  subject { described_class.new(secondary, user) }

  describe '#execute' do
    context 'when the node is nil' do
      subject { described_class.new(nil, user) }

      it 'fails and not make a request' do
        expect(Gitlab::HTTP).not_to receive(:perform_request)

        expect(subject.execute({})).to be_falsey
      end
    end

    context 'when the user is nil' do
      subject { described_class.new(secondary, nil) }

      it 'makes an unauthenticated request' do
        expect(Gitlab::HTTP).to receive(:perform_request)
                                  .with(
                                    Net::HTTP::Post,
                                    secondary.graphql_url,
                                    hash_including(headers: jwt_token_with_data(
                                      scope: ::Gitlab::Geo::API_SCOPE
                                    )))
                                  .and_return(double(success?: true, parsed_response: 'response'))

        expect(subject.execute({})).to be('response')
      end
    end

    it 'sends a request with the authenticating user id in the headers' do
      expect(Gitlab::HTTP).to receive(:perform_request)
                                .with(
                                  Net::HTTP::Post,
                                  secondary.graphql_url,
                                  hash_including(headers: jwt_token_with_data(
                                    scope: ::Gitlab::Geo::API_SCOPE,
                                    authenticating_user_id: user.id
                                  )))
                                .and_return(double(success?: true, parsed_response: 'response'))

      expect(subject.execute({})).to be('response')
    end
  end
end
