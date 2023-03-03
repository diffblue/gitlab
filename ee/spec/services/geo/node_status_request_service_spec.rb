# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::NodeStatusRequestService, :geo, feature_category: :geo_replication do
  include ::EE::GeoHelpers
  include ApiHelpers

  let_it_be(:primary)   { create(:geo_node, :primary) }
  let_it_be(:secondary) { create(:geo_node) }

  before do
    stub_current_geo_node(primary)
  end

  it_behaves_like 'a geo RequestService' do
    subject { described_class.new(secondary.find_or_build_status) }
  end

  describe '#execute' do
    before do
      stub_current_geo_node(primary)
    end

    it 'does not include id in the payload' do
      args = GeoNodeStatus.new({
        geo_node_id: secondary.id,
        status_message: nil,
        db_replication_lag_seconds: 0,
        projects_count: 10
      })

      expect(Gitlab::HTTP).to receive(:perform_request)
                                .with(
                                  Net::HTTP::Post,
                                  primary.status_url,
                                  hash_including(body: hash_not_including('id')))
                                .and_return(double(success?: true, parsed_response: { 'message' => 'Test' }))

      expect(described_class.new(args).execute).to be_truthy
    end

    it 'sends geo_node_id in the request' do
      args = GeoNodeStatus.new({
        geo_node_id: secondary.id,
        status_message: nil,
        db_replication_lag_seconds: 0,
        projects_count: 10
      })

      expect(Gitlab::HTTP).to receive(:perform_request)
                                .with(
                                  Net::HTTP::Post,
                                  primary.status_url,
                                  hash_including(body: hash_including('geo_node_id' => secondary.id)))
                                .and_return(double(success?: true, parsed_response: { 'message' => 'Test' }))

      expect(described_class.new(args).execute).to be_truthy
    end

    it 'sends all of the data in the status JSONB field in the request' do
      args = create(:geo_node_status, :healthy)

      expect(Gitlab::HTTP).to receive(:perform_request)
                                .with(
                                  Net::HTTP::Post,
                                  primary.status_url,
                                  hash_including(
                                    body: hash_including(
                                      'status' => hash_including(
                                        *GeoNodeStatus::RESOURCE_STATUS_FIELDS))))
                                .and_return(double(success?: true, parsed_response: { 'message' => 'Test' }))

      expect(described_class.new(args).execute).to be_truthy
    end
  end
end
