# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::PlanLimits::UpdateService, :enable_admin_mode, feature_category: :shared do
  describe '#execute', :freeze_time do
    let(:limits) { plan.actual_limits }
    let_it_be(:user) { create(:admin) }
    let(:current_timestamp) { Time.current.utc.to_i }
    let(:dashboard_limit_enabled_at) { Time.current.iso8601 }

    let(:params) do
      {
        enforcement_limit: 25,
        notification_limit: 20,
        pipeline_hierarchy_size: 10,
        dashboard_limit_enabled_at: dashboard_limit_enabled_at
      }
    end

    subject(:execute) { described_class.new(params, current_user: user, plan: plan).execute }

    context 'when the plan is paid' do
      let(:plan) { create(:plan, name: 'ultimate') }

      it 'does not update restricted attributes' do
        execute

        expect(limits.enforcement_limit).to eq 0
        expect(limits.notification_limit).to eq 0
        expect(limits.dashboard_limit_enabled_at).to be_nil
        expect(limits.pipeline_hierarchy_size).to eq 10
      end

      it 'does not update limits_history' do
        execute

        expect(limits.reload.limits_history).to be_empty
      end
    end

    context 'when the plan is free' do
      let(:plan) { create(:plan, name: 'free') }

      it 'updates restricted attributes' do
        execute

        expect(limits.enforcement_limit).to eq 25
        expect(limits.notification_limit).to eq 20
        expect(limits.pipeline_hierarchy_size).to eq 10
        expect(limits.dashboard_limit_enabled_at).to eq dashboard_limit_enabled_at
      end

      it 'updates limits_history for restricted attributes only' do
        execute

        expect(limits.limits_history).to eq(
          {
            'enforcement_limit' => [{ 'timestamp' => current_timestamp,
                                      'user_id' => user.id, 'username' => user.username, 'value' => 25 }],
            'notification_limit' => [{ 'timestamp' => current_timestamp,
                                       'user_id' => user.id, 'username' => user.username, 'value' => 20 }],
            "dashboard_limit_enabled_at" => [{ "timestamp" => current_timestamp, "user_id" => user.id,
                                               "username" => user.username, "value" => dashboard_limit_enabled_at }]
          }
        )
      end
    end
  end
end
