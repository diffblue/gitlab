# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SortingHelper do
  describe '#sort_direction_icon' do
    it 'returns lowest for weight' do
      expect(sort_direction_icon('weight')).to eq('sort-lowest')
    end

    it 'behaves like non-ee for other sort values' do
      expect(sort_direction_icon('milestone')).to eq('sort-lowest')
      expect(sort_direction_icon('last_joined')).to eq('sort-highest')
    end
  end

  describe '#can_sort_by_issue_weight?' do
    subject { can_sort_by_issue_weight?(viewing_issue) }

    context 'when user is viewing issues' do
      let(:viewing_issue) { true }

      before do
        instance_variable_set(:@group, build(:group))
      end

      context 'when issue_weights licensed feature is enabled' do
        before do
          stub_licensed_features(issue_weights: true)
        end

        it { is_expected.to be_truthy }
      end

      context 'when issue_weights licensed feature is disabled' do
        before do
          stub_licensed_features(issue_weights: false)
        end

        it { is_expected.to be_falsey }
      end
    end

    context 'when user is not viewing issues' do
      let(:viewing_issue) { false }

      it { is_expected.to be_falsey }
    end
  end
end
