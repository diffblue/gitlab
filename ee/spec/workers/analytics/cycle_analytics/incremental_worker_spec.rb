# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::CycleAnalytics::IncrementalWorker do
  it_behaves_like 'aggregator worker examples' do
    let(:expected_mode) { :incremental }
    let(:feature_flag) { nil } # TODO: remove when cleaning up the other worker feature flags
  end
end
