# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Minutes::NamespaceMonthlyUsage do
  let_it_be_with_refind(:namespace) do
    create(:namespace,
      shared_runners_minutes_limit: 1_000,
      extra_shared_runners_minutes_limit: 500)
  end

  let_it_be_with_refind(:current_usage) do
    create(:ci_namespace_monthly_usage,
      :with_warning_notification_level,
      namespace: namespace,
      amount_used: 100)
  end

  describe 'unique index' do
    it 'raises unique index violation' do
      expect { create(:ci_namespace_monthly_usage, namespace: namespace) }
        .to raise_error { ActiveRecord::RecordNotUnique }
    end

    it 'does not raise exception if unique index is not violated' do
      expect { create(:ci_namespace_monthly_usage, namespace: namespace, date: described_class.beginning_of_month(1.month.ago)) }
        .to change { described_class.count }.by(1)
    end
  end

  describe '.find_or_create_current' do
    subject { described_class.find_or_create_current(namespace_id: namespace.id) }

    shared_examples 'creates usage record' do
      it 'creates new record and resets minutes consumption' do
        freeze_time do
          expect { subject }.to change { described_class.count }.by(1)

          expect(subject.amount_used).to eq(0)
          expect(subject.namespace).to eq(namespace)
          expect(subject.date).to eq(described_class.beginning_of_month)
          expect(subject.notification_level).to eq(::Ci::Minutes::Notification::PERCENTAGES.fetch(:not_set))
          expect(subject.created_at).to eq(Time.current)
        end
      end

      it 'kicks off Ci::Minutes::RefreshCachedDataWorker' do
        expect(::Ci::Minutes::RefreshCachedDataWorker)
          .to receive(:perform_async)
          .with(namespace.id)

        subject
      end
    end

    shared_examples 'does not update the additional minutes' do
      it 'does not update the additional minutes' do
        expect { subject }
          .not_to change { namespace.reload.extra_shared_runners_minutes_limit }
      end
    end

    shared_examples 'attempts recalculation of additional minutes' do
      context 'when namespace has any additional minutes' do
        context 'when last known amount_used is greater than the monthly limit' do
          before do
            previous_usage.update!(amount_used: 1_200)
          end

          it 'recalculates the remaining additional minutes' do
            expect { subject }
              .to change { namespace.reload.extra_shared_runners_minutes_limit }
              .from(500).to(300)
          end

          context 'when last known amount_used is greater than the total limit' do
            before do
              previous_usage.update!(amount_used: 2_000)
            end

            it 'recalculates the remaining additional minutes' do
              expect { subject }
                .to change { namespace.reload.extra_shared_runners_minutes_limit }
                .from(500).to(0)
            end
          end

          context 'when limit is disabled' do
            before do
              namespace.update!(
                shared_runners_minutes_limit: 0,
                extra_shared_runners_minutes_limit: 0)
            end

            it_behaves_like 'does not update the additional minutes'
          end
        end

        context 'when amount_used is lower than the monthly limit' do
          before do
            previous_usage.update!(amount_used: 900)
          end

          it_behaves_like 'does not update the additional minutes'
        end
      end

      context 'when namespace does not have additional minutes' do
        before do
          namespace.update!(extra_shared_runners_minutes_limit: 0)
        end

        it_behaves_like 'does not update the additional minutes'
      end
    end

    context 'when namespace usage does not exist for current month' do
      before do
        current_usage.destroy!
      end

      it_behaves_like 'creates usage record'
      it_behaves_like 'does not update the additional minutes'

      context 'when namespace usage exists for previous month' do
        let!(:previous_usage) do
          create(:ci_namespace_monthly_usage,
            namespace: namespace,
            date: described_class.beginning_of_month(1.month.ago))
        end

        it_behaves_like 'creates usage record'
        it_behaves_like 'attempts recalculation of additional minutes'
      end

      context 'when inside a transaction in ci database' do
        let!(:previous_usage) do
          create(:ci_namespace_monthly_usage,
            namespace: namespace,
            date: described_class.beginning_of_month(3.months.ago))
        end

        let(:project) { create(:project, namespace: namespace) }
        let(:pipeline) { create(:ci_pipeline, project: project) }
        let(:build) { create(:ci_build, :created, pipeline: pipeline) }

        before do
          namespace.clear_memoization(:ci_minutes_usage)
          create(:ci_runner, :instance_type)
        end

        subject do
          pipeline.transaction do
            pipeline.touch
            described_class.find_or_create_current(namespace_id: namespace.id)
          end
        end

        it_behaves_like 'creates usage record'
        it_behaves_like 'attempts recalculation of additional minutes'
      end

      context 'when last known usage is more than 1 month ago' do
        let!(:previous_usage) do
          create(:ci_namespace_monthly_usage,
            namespace: namespace,
            date: described_class.beginning_of_month(3.months.ago))
        end

        it_behaves_like 'creates usage record'
        it_behaves_like 'attempts recalculation of additional minutes'
      end

      context 'when namespace usage exists for previous months' do
        let!(:previous_usage) do
          create(:ci_namespace_monthly_usage,
            namespace: namespace,
            date: described_class.beginning_of_month(1.month.ago))
        end

        let!(:old_usage) do
          create(:ci_namespace_monthly_usage,
            namespace: namespace,
            date: described_class.beginning_of_month(2.months.ago),
            amount_used: 2_000)
        end

        it_behaves_like 'creates usage record'
        it_behaves_like 'attempts recalculation of additional minutes'
      end

      context 'when a usage for another namespace exists for the current month' do
        let!(:usage) { create(:ci_namespace_monthly_usage) }

        it_behaves_like 'creates usage record'
        it_behaves_like 'does not update the additional minutes'
      end
    end

    context 'when namespace usage exists for the current month' do
      it 'returns the existing usage' do
        freeze_time do
          expect(subject).to eq(current_usage)
        end
      end

      it_behaves_like 'does not update the additional minutes'
    end
  end

  describe '#increase_usage' do
    it_behaves_like 'CI minutes increase usage'
  end

  describe '.for_namespace' do
    it 'returns usages for the namespace' do
      create(:ci_namespace_monthly_usage, namespace: create(:namespace))

      usages = described_class.for_namespace(namespace)

      expect(usages).to contain_exactly(current_usage)
    end
  end

  describe '.previous_usage' do
    subject { described_class.previous_usage(namespace) }

    context 'when there are no usage records' do
      it { is_expected.to be_nil }
    end

    context 'when there are usage records for the previous month' do
      let(:current_month) { described_class.beginning_of_month }

      let!(:previous_month_usage) { create(:ci_namespace_monthly_usage, namespace: namespace, amount_used: 200, date: current_month - 2.months) }
      let!(:very_old_usage) { create(:ci_namespace_monthly_usage, namespace: namespace, amount_used: 300, date: current_month - 3.months) }

      it { is_expected.to eq(previous_month_usage) }
    end
  end

  describe '.reset_current_usage', :aggregate_failures do
    subject { described_class.reset_current_usage(namespace) }

    it 'resets current usage and notification level' do
      subject

      current_usage.reload
      expect(current_usage.amount_used).to eq(0)
      expect(current_usage.notification_level).to eq(Ci::Minutes::Notification::PERCENTAGES.fetch(:not_set))
    end

    it 'does not reset data from previous months' do
      previous_usage = create(:ci_namespace_monthly_usage,
        :with_warning_notification_level,
        namespace: namespace,
        date: 1.month.ago.beginning_of_month.to_date)

      subject

      previous_usage.reload
      expect(previous_usage.amount_used).to eq(100)
      expect(previous_usage.notification_level).to eq(Ci::Minutes::Notification::PERCENTAGES.fetch(:warning))
    end

    it 'does not reset data from other namespaces' do
      another_usage = create(:ci_namespace_monthly_usage, :with_warning_notification_level)

      subject

      another_usage.reload
      expect(another_usage.amount_used).to eq(100)
      expect(another_usage.notification_level).to eq(Ci::Minutes::Notification::PERCENTAGES.fetch(:warning))
    end
  end

  describe '.reset_current_notification_level' do
    subject { described_class.reset_current_notification_level(namespace) }

    it 'resets current notification level' do
      expect { subject }
        .to change { current_usage.reload.notification_level }
        .to(Ci::Minutes::Notification::PERCENTAGES.fetch(:not_set))
    end

    it 'does not reset notification level from previous months' do
      previous_usage = create(:ci_namespace_monthly_usage,
        :with_warning_notification_level,
        namespace: namespace,
        date: 1.month.ago.beginning_of_month.to_date)

      expect { subject }
        .not_to change { previous_usage.reload.notification_level }
    end

    it 'does not reset notification level from other namespaces' do
      another_usage = create(:ci_namespace_monthly_usage, :with_warning_notification_level)

      expect { subject }
        .not_to change { another_usage.reload.notification_level }
    end
  end

  describe '#usage_notified?' do
    subject { current_usage.usage_notified?(remaining_percentage) }

    before do
      current_usage.update!(notification_level: 30)
    end

    context 'when parameter is different than notification level' do
      let(:remaining_percentage) { 5 }

      it { is_expected.to be_falsey }
    end

    context 'when parameter is same as the notification level' do
      let(:remaining_percentage) { 30 }

      it { is_expected.to be_truthy }
    end
  end

  describe '#total_usage_notified?' do
    before do
      current_usage.update!(notification_level: notification_level)
    end

    subject { current_usage.total_usage_notified? }

    context 'notification level is higher than zero' do
      let(:notification_level) { 30 }

      it { is_expected.to be_falsey }
    end

    context 'when notification level is zero' do
      let(:notification_level) { 0 }

      it { is_expected.to be_truthy }
    end
  end

  describe 'scope: .by_namespace_and_date', :freeze_time do
    let_it_be(:date) { Date.today.beginning_of_month }
    let_it_be(:namespace) { create(:namespace) }
    let_it_be(:ci_usage) { create(:ci_namespace_monthly_usage, namespace: namespace, amount_used: 200, date: date) }
    let_it_be(:other_namespace) { create(:namespace) }

    context 'when there are matching records' do
      it 'returns the matching records' do
        expect(described_class.by_namespace_and_date(namespace, date)).to eq([ci_usage])
      end
    end

    context 'when there are no matching records' do
      it 'returns an empty array' do
        expect(described_class.by_namespace_and_date(other_namespace, date)).to eq([])
      end
    end
  end
end
