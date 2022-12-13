# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UpdateGitlabSubscriptionsStartAtPostEoa, feature_category: :purchase do
  let(:migration) { described_class.new }
  let(:eoa_rollout_date) { described_class::GitlabSubscription::EOA_ROLLOUT_DATE.to_date }

  let(:gitlab_subscriptions_table) { table(:gitlab_subscriptions) }
  let(:plans_table) { table(:plans) }
  let(:namespaces_table) { table(:namespaces) }

  let!(:namespace_one) { namespaces_table.create!(name: 'namespace1', path: 'path1') }
  let!(:namespace_two) { namespaces_table.create!(name: 'namespace2', path: 'path2') }
  let!(:free_plan) { plans_table.create!(name: 'free') }
  let!(:silver_plan) { plans_table.create!(name: 'silver') }
  let!(:gold_plan) { plans_table.create!(name: 'gold') }
  let!(:premium_plan) { plans_table.create!(name: 'premium') }
  let!(:ultimate_plan) { plans_table.create!(name: 'ultimate') }

  describe '#up' do
    context 'when not on GitLab.com' do
      before do
        allow(Gitlab).to receive(:com?).and_return(false)
      end

      it 'does not do any update' do
        expect(migration).not_to receive(:update_hosted_plan_for_subscription)

        migration.up
      end
    end

    context 'when on Gitlab.com' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      it 'updates the silver and gold post-EoA subscriptions' do
        silver_sub = gitlab_subscriptions_table.create!(
          start_date: eoa_rollout_date + 2.days,
          hosted_plan_id: silver_plan.id,
          namespace_id: namespace_two.id
        )

        gold_sub = gitlab_subscriptions_table.create!(
          start_date: eoa_rollout_date + 5.days,
          hosted_plan_id: gold_plan.id,
          namespace_id: namespace_one.id
        )

        migration.up

        expect(silver_sub.reload.hosted_plan_id).to eq(premium_plan.id)
        expect(gold_sub.reload.hosted_plan_id).to eq(ultimate_plan.id)
      end

      context 'when a subscription occurred before eoa date' do
        it 'is not being updated' do
          silver_sub = gitlab_subscriptions_table.create!(
            start_date: eoa_rollout_date - 3.days,
            hosted_plan_id: silver_plan.id,
            namespace_id: namespace_two.id
          )

          migration.up

          expect(silver_sub.reload.hosted_plan_id).to eq(silver_plan.id)
        end
      end

      context 'when a subscription other than gold and silver was bought after eoa date' do
        it 'is not being updated' do
          free_sub = gitlab_subscriptions_table.create!(
            start_date: eoa_rollout_date + 2.days,
            hosted_plan_id: free_plan.id,
            namespace_id: namespace_one.id
          )

          migration.up

          expect(free_sub.reload.hosted_plan_id).to eq(free_plan.id)
        end
      end
    end
  end
end
