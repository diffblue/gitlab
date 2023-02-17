# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::CycleAnalytics::Summary::BaseDoraSummary, feature_category: :devops_reports do
  describe '#metric_key' do
    it 'is required to be overloaded' do
      expect do
        described_class.new(stage: nil, current_user: nil, options: { from: Time.zone.now }).value
      end.to raise_error(NoMethodError, 'metric_key must be overloaded in child class')
    end
  end
end
