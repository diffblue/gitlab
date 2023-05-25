# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PlanLimits, feature_category: :consumables_cost_management do
  describe '#dashboard_storage_limit_enabled?' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:plan_limits) { create(:plan_limits) }

    subject { plan_limits.dashboard_storage_limit_enabled? }

    where(:storage_size_limit, :dashboard_limit_enabled_at, :result) do
      10 | Time.current | true
      0  | nil          | false
      0  | Time.current | false
    end

    with_them do
      before do
        plan_limits.update!(
          storage_size_limit: storage_size_limit,
          dashboard_limit_enabled_at: dashboard_limit_enabled_at
        )
      end

      it { is_expected.to eq result }
    end
  end
end
