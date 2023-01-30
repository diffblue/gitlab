# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::Weight, feature_category: :team_planning do
  let_it_be(:work_item) { create(:work_item, :task, weight: 1) }

  describe '.quick_action_params' do
    subject { described_class.quick_action_params }

    it { is_expected.to include(:weight) }
  end

  describe '#weight' do
    subject { described_class.new(work_item).weight }

    it { is_expected.to eq(work_item.weight) }
  end
end
