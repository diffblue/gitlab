# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::ValueStreamDashboard::Count, feature_category: :value_stream_management do
  subject(:model) { build(:value_stream_dashboard_count) }

  describe 'associations' do
    it { is_expected.to belong_to(:namespace) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:namespace_id) }
    it { is_expected.to validate_presence_of(:recorded_at) }
    it { is_expected.to validate_presence_of(:count) }
  end
end
