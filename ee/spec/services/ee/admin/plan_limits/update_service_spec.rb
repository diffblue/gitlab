# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::PlanLimits::UpdateService, :enable_admin_mode, feature_category: :shared do
  let_it_be(:user) { create(:admin) }

  let(:params) do
    {
      enforcement_limit: 25,
      notification_limit: 20,
      pipeline_hierarchy_size: 10
    }
  end

  context 'when the plan is paid' do
    let(:plan) { create(:plan, name: 'ultimate') }
    let(:limits) { plan.actual_limits }

    it 'does not update restricted attributes' do
      limits = plan.actual_limits

      described_class.new(params, current_user: user, plan: plan).execute

      expect(limits.enforcement_limit).to eq 0
      expect(limits.notification_limit).to eq 0
      expect(limits.pipeline_hierarchy_size).to eq 10
    end
  end

  context 'when the plan is free' do
    let(:plan) { create(:plan, name: 'free') }
    let(:limits) { plan.actual_limits }

    it 'updates restricted attributes' do
      described_class.new(params, current_user: user, plan: plan).execute

      expect(limits.enforcement_limit).to eq 25
      expect(limits.notification_limit).to eq 20
      expect(limits.pipeline_hierarchy_size).to eq 10
    end
  end
end
