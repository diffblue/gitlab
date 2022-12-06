# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Ci::Minutes::Quota, feature_category: :continuous_integration do
  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:namespace) { create(:namespace) }
  let_it_be_with_reload(:another_group) { create(:group) }

  let(:quota) { described_class.new(namespace) }
  let(:namespace_monthly_quota) { 400 }
  let(:application_monthly_quota) { 400 }
  let(:purchased_minutes) { 0 }

  before do
    namespace.shared_runners_minutes_limit = namespace_monthly_quota
    namespace.extra_shared_runners_minutes_limit = purchased_minutes
    allow(::Gitlab::CurrentSettings).to receive(:shared_runners_minutes).and_return(application_monthly_quota)
  end

  describe '#enabled?' do
    subject { quota.enabled? }

    where(:namespace_monthly_quota, :application_monthly_quota, :purchased_minutes, :result) do
      0   | 100 | 0  | false
      0   | 100 | 10 | true
      nil | 100 | 10 | true
      nil | 100 | 0  | true
      20  | 100 | 0  | true
      nil | nil | 0  | false
      nil | 0   | 0  | false
    end

    with_them do
      it { is_expected.to eq(result) }

      context 'when namespace is not root' do
        before do
          namespace.parent = another_group
        end

        it { is_expected.to eq(false) }
      end
    end
  end

  describe '#total' do
    subject { quota.total }

    where(:namespace_monthly_quota, :application_monthly_quota, :purchased_minutes, :result) do
      20  | 100 | 30 | 50
      nil | 100 | 30 | 130
      20  | 100 | 0  | 20
      0   | 0   | 30 | 30
      nil | 0   | 30 | 30
    end

    with_them do
      it { is_expected.to eq(result) }
    end
  end

  describe '#monthly' do
    subject { quota.monthly }

    where(:namespace_monthly_quota, :application_monthly_quota, :result) do
      20  | 100 | 20
      nil | 100 | 100
      100 | nil | 100
      0   | 100 | 0
      nil | nil | 0
    end

    with_them do
      it { is_expected.to eq(result) }
    end
  end

  describe '#purchased and #any_purchased?' do
    where(:purchased_minutes, :purchased, :any_purchased) do
      nil | 0  | false
      0   | 0  | false
      10  | 10 | true
    end

    with_them do
      it do
        expect(quota.purchased).to eq(purchased)
        expect(quota.any_purchased?).to eq(any_purchased)
      end
    end
  end

  describe '#recalculate_remaining_purchased_minutes!' do
    subject { quota.recalculate_remaining_purchased_minutes! }

    where(:purchased_minutes, :namespace_monthly_quota, :previous_amount_used, :expected_purchased_limit) do
      200 | 400 | 0   | 200 # no minutes used
      200 | 0   | 0   | 200 # monthly limit disabled
      0   | 0   | 0   | 0   # monthly limit disabled and no purchased minutes
      200 | 400 | nil | 200 # no previous month usage
      200 | 400 | 300 | 200 # previous usage < monthly limit
      200 | 400 | 500 | 100 # previous usage > monthly limit => purchased minutes reduced
      0   | 400 | 500 | 0   # no purchased minutes = nothing reduced
      200 | 400 | 600 | 0   # previous usage == total limit => purchased minutes reduced
      200 | 400 | 800 | 0   # previous usage > total limit => purchased minutes reduced but not negative
    end

    with_them do
      before do
        if previous_amount_used
          create(:ci_namespace_monthly_usage,
            namespace: namespace,
            date: Ci::Minutes::NamespaceMonthlyUsage.beginning_of_month(2.months.ago),
            amount_used: previous_amount_used)

          create(:ci_namespace_monthly_usage,
            namespace: namespace,
            date: Ci::Minutes::NamespaceMonthlyUsage.beginning_of_month(3.months.ago),
            amount_used: 5_000)
        end
      end

      it 'has the expected purchased minutes' do
        subject
        expect(namespace.extra_shared_runners_minutes_limit).to eq(expected_purchased_limit)
      end
    end
  end
end
