# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataNonSqlMetrics do
  include UsageDataHelpers

  before do
    stub_usage_data_connections
    stub_database_flavor_check
  end

  describe '.data' do
    it 'does make instrumentations_class DB calls', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/356772' do
      recorder = ActiveRecord::QueryRecorder.new do
        described_class.data
      end

      expect(recorder.count).to eq(67)
    end
  end
end
