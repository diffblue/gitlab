# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Geo::Logger, feature_category: :geo_replication do
  it 'uses the same log_level defined in Rails' do
    allow(Rails.logger).to receive(:level) { 99 }

    logger = described_class.build

    expect(logger.level).to eq(99)
  end
end
