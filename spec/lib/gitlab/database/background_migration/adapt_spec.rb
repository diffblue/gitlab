# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::BackgroundMigration::Adapt do
  let(:connection) { Gitlab::Database.database_base_models[:main].connection }

  around do |example|
    Gitlab::Database::SharedModel.using_connection(connection) do
      example.run
    end
  end

  describe '.adapt!' do
    subject { described_class.adapt!(migration, indicator_class) }

    let(:migration) { create(:batched_background_migration, :active, batch_size: 2) }

    let(:indicator_class) { class_double("Gitlab::Database::BackgroundMigration::Adapt::AutovacuumActiveOnTable") }
    let(:indicator) { instance_double("Gitlab::Database::BackgroundMigration::Adapt::AutovacuumActiveOnTable") }

    before do
      allow(indicator_class).to receive(:new).with(migration.adapt_context).and_return(indicator)
    end

    let(:stop_signal) { described_class::StopSignal.new(indicator_class, reason: 'taking a break') }
    let(:normal_signal) { described_class::NormalSignal.new(indicator_class, reason: 'carry on with stuff') }

    it 'puts the migration on hold when given the stop signal' do
      expect(indicator).to receive(:evaluate).and_return(stop_signal)
      expect(migration).to receive(:hold!)
      expect(migration).not_to receive(:optimize!)

      subject
    end

    it 'optimizes the migration when given the normal signal' do
      expect(indicator).to receive(:evaluate).and_return(normal_signal)
      expect(migration).to receive(:optimize!)
      expect(migration).not_to receive(:hold!)

      subject
    end

    it 'does not fail when the indicator raises an error' do
      expect(indicator).to receive(:evaluate).and_raise(RuntimeError, 'I dont know whats happening')

      expect { subject }.not_to raise_error
    end

    context 'with default indicator (integration test)', :freeze_time do
      subject { described_class.adapt!(migration) }

      let(:default_indicator_class) { Gitlab::Database::BackgroundMigration::Adapt::AutovacuumActiveOnTable }

      before do
        allow_next_instance_of(default_indicator_class) do |instance|
          expect(instance).to receive(:evaluate).and_return(stop_signal)
        end
      end

      it 'puts the migration on hold when given the stop signal' do
        expect { subject }.to change { migration.on_hold? }.from(false).to(true)
      end
    end
  end
end
