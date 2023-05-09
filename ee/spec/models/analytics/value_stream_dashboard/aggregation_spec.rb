# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::ValueStreamDashboard::Aggregation, type: :model, feature_category: :value_stream_management do
  subject(:model) { build(:value_stream_dashboard_aggregation) }

  describe 'associations' do
    it { is_expected.to belong_to(:namespace).optional(false) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:namespace_id) }
    it { is_expected.to validate_inclusion_of(:enabled).in_array([true, false]) }
  end
end
