# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Minutes::NamespaceMonthlyUsage do
  let_it_be(:namespace) { create(:namespace) }

  describe 'unique index' do
    before_all do
      create(:ci_namespace_monthly_usage, namespace: namespace)
    end

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
        end
      end
    end

    context 'when namespace usage does not exist' do
      it_behaves_like 'creates usage record'
    end

    context 'when namespace usage exists for previous months' do
      before do
        create(:ci_namespace_monthly_usage, namespace: namespace, date: described_class.beginning_of_month(2.months.ago))
      end

      it_behaves_like 'creates usage record'
    end

    context 'when namespace usage exists for the current month' do
      it 'returns the existing usage' do
        freeze_time do
          usage = create(:ci_namespace_monthly_usage, namespace: namespace)

          expect(subject).to eq(usage)
        end
      end
    end

    context 'when a usage for another namespace exists for the current month' do
      let!(:usage) { create(:ci_namespace_monthly_usage) }

      it_behaves_like 'creates usage record'
    end
  end

  describe '.increase_usage' do
    subject { described_class.increase_usage(usage, amount) }

    let(:usage) { create(:ci_namespace_monthly_usage, namespace: namespace, amount_used: 100.0) }

    context 'when amount is greater than 0' do
      let(:amount) { 10.5 }

      it 'updates the current month usage' do
        subject

        expect(usage.reload.amount_used).to eq(110.5)
      end
    end

    context 'when amount is less or equal to 0' do
      let(:amount) { -2.0 }

      it 'does not update the current month usage' do
        subject

        expect(usage.reload.amount_used).to eq(100.0)
      end
    end
  end

  describe '.for_namespace' do
    it 'returns usages for the namespace' do
      matching_usage = create(:ci_namespace_monthly_usage, namespace: namespace)
      create(:ci_namespace_monthly_usage, namespace: create(:namespace))

      usages = described_class.for_namespace(namespace)

      expect(usages).to contain_exactly(matching_usage)
    end
  end
end
