# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::StorageHelper, feature_category: :consumables_cost_management do
  using RSpec::Parameterized::TableSyntax

  describe '#used_storage_percentage' do
    it 'returns the given usage ratio as a human readable percentage string' do
      expect(helper.used_storage_percentage(0.75)).to eq('75%')
    end

    where(:usage_ratio, :expected_percentage) do
      0.502 | '50%'
      0.405 | '41%'
      0.808 | '81%'
    end

    with_them do
      it 'rounds the usage ratio to the nearest whole integer percentage' do
        expect(helper.used_storage_percentage(usage_ratio)).to eq(expected_percentage)
      end
    end

    it 'expresses usage ratios higher than 1 as a percentage greater than 100%' do
      expect(helper.used_storage_percentage(2.05)).to eq('205%')
    end
  end
end
