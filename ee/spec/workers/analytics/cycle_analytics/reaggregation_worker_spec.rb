# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::CycleAnalytics::ReaggregationWorker, feature_category: :value_stream_management do
  it_behaves_like 'aggregator worker examples' do
    let(:expected_mode) { :full }
  end
end
