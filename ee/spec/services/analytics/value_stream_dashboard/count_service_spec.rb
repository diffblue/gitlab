# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::ValueStreamDashboard::CountService, feature_category: :value_stream_management do
  it 'returns successful response' do
    aggregation = create(:value_stream_dashboard_aggregation)
    count_service = described_class.new(aggregation: aggregation, cursor: {})

    service_response = count_service.execute

    expect(service_response).to be_success
    expect(service_response.payload[:cursor]).to eq({})
  end
end
