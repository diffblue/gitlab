# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::WebHooks::RateLimiter, :saas, :clean_gitlab_redis_rate_limiting, :freeze_time do
  before_all do
    create(:plan_limits, :premium_plan, web_hook_calls_low: 1, web_hook_calls_mid: 2, web_hook_calls: 3)
    create(:plan_limits, :ultimate_plan, web_hook_calls_low: 4, web_hook_calls_mid: 5, web_hook_calls: 6)
    create(:plan_limits, :opensource_plan, web_hook_calls_low: 7, web_hook_calls_mid: 8, web_hook_calls: 9)
    create(:plan_limits, :bronze_plan, web_hook_calls_low: 9, web_hook_calls_mid: 8, web_hook_calls: 7)
    create(:plan_limits, :silver_plan, web_hook_calls_low: 6, web_hook_calls_mid: 5, web_hook_calls: 4)
    create(:plan_limits, :gold_plan, web_hook_calls_low: 3, web_hook_calls_mid: 2, web_hook_calls: 1)
    create(:plan_limits, :premium_trial_plan, web_hook_calls_low: 1, web_hook_calls_mid: 3, web_hook_calls: 2)
    create(:plan_limits, :ultimate_trial_plan, web_hook_calls_low: 2, web_hook_calls_mid: 1, web_hook_calls: 3)
  end

  let_it_be(:group_premium_plan) { create(:group_with_plan, plan: :premium_plan) }
  let_it_be(:group_ultimate_plan) { create(:group_with_plan, plan: :ultimate_plan) }
  let_it_be(:group_opensource_plan) { create(:group_with_plan, plan: :opensource_plan) }
  let_it_be(:group_bronze_plan) { create(:group_with_plan, plan: :bronze_plan) }
  let_it_be(:group_silver_plan) { create(:group_with_plan, plan: :silver_plan) }
  let_it_be(:group_gold_plan) { create(:group_with_plan, plan: :gold_plan) }
  let_it_be(:group_premium_trial_plan) { create(:group_with_plan, plan: :premium_trial_plan) }
  let_it_be(:group_ultimate_trial_plan) { create(:group_with_plan, plan: :ultimate_trial_plan) }
  let_it_be(:project_premium_plan) { create(:project, group: group_premium_plan) }
  let_it_be(:project_ultimate_plan) { create(:project, group: group_ultimate_plan) }

  let_it_be_with_reload(:project_hook_with_premium_plan) { create(:project_hook, project: project_premium_plan) }
  let_it_be_with_reload(:project_hook_with_ultimate_plan) { create(:project_hook, project: project_ultimate_plan) }
  let_it_be_with_reload(:group_hook_with_opensource_plan) { create(:group_hook, group: group_opensource_plan) }
  let_it_be_with_reload(:group_hook_with_bronze_plan) { create(:group_hook, group: group_bronze_plan) }
  let_it_be_with_reload(:group_hook_with_silver_plan) { create(:group_hook, group: group_silver_plan) }
  let_it_be_with_reload(:group_hook_with_gold_plan) { create(:group_hook, group: group_gold_plan) }
  let_it_be_with_reload(:group_hook_with_premium_trial_plan) { create(:group_hook, group: group_premium_trial_plan) }
  let_it_be_with_reload(:group_hook_with_ultimate_trial_plan) { create(:group_hook, group: group_ultimate_trial_plan) }

  describe 'LIMIT_MAP' do
    it 'contains all paid plans' do
      keys = described_class::LIMIT_MAP.keys

      expect(keys).to match_array(Plan::PAID_HOSTED_PLANS)
    end
  end

  describe '#rate_limit!' do
    def rate_limit!
      described_class.new(hook).rate_limit!
    end

    context 'when there is no GitLab subscription' do
      let(:hook) { project_hook_with_premium_plan }
      let(:root_namespace) { hook.parent.root_namespace }

      before do
        root_namespace.gitlab_subscription.destroy!
        root_namespace.reload
      end

      it 'can never be rate-limited' do
        expect(Gitlab::ApplicationRateLimiter).not_to receive(:throttled?)

        rate_limit!
      end
    end

    context 'when there are no reasons preventing the rate limit' do
      let(:hook) { project_hook_with_premium_plan }

      it 'can be rate limited' do
        expect(Gitlab::ApplicationRateLimiter).to receive(:throttled?)

        rate_limit!
      end
    end

    describe 'integration-style test of limits' do
      using RSpec::Parameterized::TableSyntax

      where(:hook, :seats, :rate_limit_name, :limit) do
        ref(:project_hook_with_premium_plan)  | 99    | :web_hook_calls_low  | 1
        ref(:project_hook_with_premium_plan)  | 100   | :web_hook_calls_mid  | 2
        ref(:project_hook_with_premium_plan)  | 399   | :web_hook_calls_mid  | 2
        ref(:project_hook_with_premium_plan)  | 400   | :web_hook_calls      | 3

        ref(:project_hook_with_ultimate_plan) | 999   | :web_hook_calls_low  | 4
        ref(:project_hook_with_ultimate_plan) | 1_000 | :web_hook_calls_mid  | 5
        ref(:project_hook_with_ultimate_plan) | 4_999 | :web_hook_calls_mid  | 5
        ref(:project_hook_with_ultimate_plan) | 5_000 | :web_hook_calls      | 6

        ref(:group_hook_with_opensource_plan) | 999   | :web_hook_calls_low  | 7
        ref(:group_hook_with_opensource_plan) | 1_000 | :web_hook_calls_mid  | 8
        ref(:group_hook_with_opensource_plan) | 4_999 | :web_hook_calls_mid  | 8
        ref(:group_hook_with_opensource_plan) | 5_000 | :web_hook_calls      | 9

        ref(:group_hook_with_bronze_plan) | 99    | :web_hook_calls_low  | 9
        ref(:group_hook_with_bronze_plan) | 100   | :web_hook_calls_mid  | 8
        ref(:group_hook_with_bronze_plan) | 399   | :web_hook_calls_mid  | 8
        ref(:group_hook_with_bronze_plan) | 400   | :web_hook_calls      | 7

        ref(:group_hook_with_silver_plan) | 99    | :web_hook_calls_low  | 6
        ref(:group_hook_with_silver_plan) | 100   | :web_hook_calls_mid  | 5
        ref(:group_hook_with_silver_plan) | 399   | :web_hook_calls_mid  | 5
        ref(:group_hook_with_silver_plan) | 400   | :web_hook_calls      | 4

        ref(:group_hook_with_gold_plan)   | 999   | :web_hook_calls_low  | 3
        ref(:group_hook_with_gold_plan)   | 1_000 | :web_hook_calls_mid  | 2
        ref(:group_hook_with_gold_plan)   | 4_999 | :web_hook_calls_mid  | 2
        ref(:group_hook_with_gold_plan)   | 5_000 | :web_hook_calls      | 1

        ref(:group_hook_with_premium_trial_plan)  | 99  | :web_hook_calls_low  | 1
        ref(:group_hook_with_premium_trial_plan)  | 100 | :web_hook_calls_mid  | 3
        ref(:group_hook_with_premium_trial_plan)  | 399 | :web_hook_calls_mid  | 3
        ref(:group_hook_with_premium_trial_plan)  | 400 | :web_hook_calls      | 2

        ref(:group_hook_with_ultimate_trial_plan) | 999   | :web_hook_calls_low  | 2
        ref(:group_hook_with_ultimate_trial_plan) | 1_000 | :web_hook_calls_mid  | 1
        ref(:group_hook_with_ultimate_trial_plan) | 4_999 | :web_hook_calls_mid  | 1
        ref(:group_hook_with_ultimate_trial_plan) | 5_000 | :web_hook_calls      | 3
      end

      with_them do
        let(:root_namespace) { hook.parent.root_ancestor }

        before do
          allow(root_namespace.gitlab_subscription).to receive(:seats).and_return(seats)
        end

        it 'rate limits correctly' do
          expect(Gitlab::ApplicationRateLimiter).to receive(:throttled?)
            .exactly(limit + 1).times
            .with(
              rate_limit_name,
              scope: [root_namespace],
              threshold: limit
            ).and_call_original

          limit.times { expect(rate_limit!).to eq(false) }

          expect(rate_limit!).to eq(true)
        end
      end
    end
  end
end
