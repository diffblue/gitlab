# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Subscriptions::NewPlanPresenter, feature_category: :subscription_management do
  describe '#title' do
    using RSpec::Parameterized::TableSyntax

    where(:legacy_name, :new_title) do
      'bronze'   | 'Bronze'
      'silver'   | 'Premium'
      'gold'     | 'Ultimate'
      'premium'  | 'Premium'
      'ultimate' | 'Ultimate'
    end

    with_them do
      it 'returns the correct title for new plans' do
        legacy_plan = build("#{legacy_name}_plan".to_sym)

        expect(described_class.new(legacy_plan).title).to eq(new_title)
      end
    end
  end
end
