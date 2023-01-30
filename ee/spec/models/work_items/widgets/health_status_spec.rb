# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::HealthStatus, feature_category: :team_planning do
  let_it_be(:work_item) { create(:work_item, :objective, health_status: :on_track) }

  describe '.quick_action_params' do
    subject { described_class.quick_action_params }

    it { is_expected.to include(:health_status) }
  end

  describe '#health_status' do
    subject { described_class.new(work_item).health_status }

    it { is_expected.to eq(work_item.health_status) }
  end
end
