# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::RequirementLegacy, feature_category: :requirements_management do
  let_it_be_with_reload(:work_item) { create(:work_item, :requirement, description: 'A description') }

  describe '.type' do
    subject { described_class.type }

    it { is_expected.to eq(:requirement_legacy) }
  end

  describe '#type' do
    subject { described_class.new(work_item).type }

    it { is_expected.to eq(:requirement_legacy) }
  end

  describe '#legacy_iid' do
    subject { described_class.new(work_item).legacy_iid }

    it { is_expected.to eq(work_item.requirement.iid) }
  end
end
