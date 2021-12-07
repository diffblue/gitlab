# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Samplers::DatabaseSampler do
  subject { described_class.new }

  it_behaves_like 'metrics sampler', 'DATABASE_SAMPLER'

  describe '#sample' do
    let(:main_labels) do
      {
        class: 'ActiveRecord::Base',
        host: ApplicationRecord.database.config['host'],
        port: ApplicationRecord.database.config['port'],
        db_config_name: 'main'
      }
    end

    let(:ci_labels) do
      {
        class: 'Ci::ApplicationRecord',
        host: Ci::ApplicationRecord.database.config['host'],
        port: Ci::ApplicationRecord.database.config['port'],
        db_config_name: 'ci'
      }
    end

    let(:main_replica_labels) do
      {
        class: 'ActiveRecord::Base',
        host: 'main-replica-host',
        port: 2345,
        db_config_name: 'main_replica'
      }
    end

    let(:ci_replica_labels) do
      {
        class: 'Ci::ApplicationRecord',
        host: 'ci-replica-host',
        port: 3456,
        db_config_name: 'ci_replica'
      }
    end

    before do
      allow(Gitlab::Database).to receive(:database_base_models)
        .and_return({ main: ActiveRecord::Base, ci: Ci::ApplicationRecord })
    end

    context 'when all base models are connected', :add_ci_connection do
      it 'samples connection pool statistics for all primaries' do
        expect_metrics_with_labels(main_labels)
        expect_metrics_with_labels(ci_labels)

        subject.sample
      end

      context 'when replica hosts are configured' do
        let(:main_load_balancer) { ActiveRecord::Base.load_balancer } # rubocop:disable Database/MultipleDatabases
        let(:ci_load_balancer) { Ci::ApplicationRecord.load_balancer }

        let(:main_replica_host) { main_load_balancer.host }
        let(:ci_replica_host) { ci_load_balancer.host }

        before do
          allow(main_load_balancer).to receive(:primary_only?).and_return(false)
          allow(ci_load_balancer).to receive(:primary_only?).and_return(false)

          allow(main_replica_host).to receive(:host).and_return('main-replica-host')
          allow(ci_replica_host).to receive(:host).and_return('ci-replica-host')

          allow(main_replica_host).to receive(:port).and_return(2345)
          allow(ci_replica_host).to receive(:port).and_return(3456)

          allow(Gitlab::Database).to receive(:db_config_name)
            .with(main_replica_host.connection)
            .and_return('main_replica')

          allow(Gitlab::Database).to receive(:db_config_name)
            .with(ci_replica_host.connection)
            .and_return('ci_replica')
        end

        it 'samples connection pool statistics for primaries and replicas' do
          expect_metrics_with_labels(main_labels)
          expect_metrics_with_labels(ci_labels)
          expect_metrics_with_labels(main_replica_labels)
          expect_metrics_with_labels(ci_replica_labels)

          subject.sample
        end
      end
    end

    context 'when a base model is not connected', :add_ci_connection do
      before do
        allow(Ci::ApplicationRecord).to receive(:connected?).and_return(false)
      end

      it 'records no samples for that primary' do
        expect_metrics_with_labels(main_labels)
        expect_no_metrics_with_labels(ci_labels)

        subject.sample
      end

      context 'when the base model has replica connections' do
        let(:ci_load_balancer) { Ci::ApplicationRecord.load_balancer }
        let(:ci_replica_host) { ci_load_balancer.host }

        before do
          allow(ci_load_balancer).to receive(:primary_only?).and_return(false)
          allow(ci_replica_host).to receive(:host).and_return('ci-replica-host')
          allow(ci_replica_host).to receive(:port).and_return(3456)

          allow(Gitlab::Database).to receive(:db_config_name)
            .with(ci_replica_host.connection)
            .and_return('ci_replica')
        end

        it 'still records the replica metrics' do
          expect_metrics_with_labels(main_labels)
          expect_no_metrics_with_labels(ci_labels)
          expect_metrics_with_labels(ci_replica_labels)

          subject.sample
        end
      end
    end

    def expect_metrics_with_labels(labels)
      expect(subject.metrics[:size]).to receive(:set).with(labels, a_value >= 1)
      expect(subject.metrics[:connections]).to receive(:set).with(labels, a_value >= 1)
      expect(subject.metrics[:busy]).to receive(:set).with(labels, a_value >= 1)
      expect(subject.metrics[:dead]).to receive(:set).with(labels, a_value >= 0)
      expect(subject.metrics[:waiting]).to receive(:set).with(labels, a_value >= 0)
    end

    def expect_no_metrics_with_labels(labels)
      described_class::METRIC_DESCRIPTIONS.each_key do |metric|
        expect(subject.metrics[metric]).not_to receive(:set).with(labels, anything)
      end
    end
  end
end
