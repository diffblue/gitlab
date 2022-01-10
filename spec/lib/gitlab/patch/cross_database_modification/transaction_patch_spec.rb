# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Patch::CrossDatabaseModification::TransactionPatch do
  let(:transaction_klass) do
    Class.new do
      prepend Gitlab::Patch::CrossDatabaseModification::TransactionPatch

      def materialize!
        ApplicationRecord.connection.execute(%q{SELECT 'materialize_test'})
      end

      def rollback
        ApplicationRecord.connection.execute(%q{SELECT 'rollback_test'})
      end

      def commit
        ApplicationRecord.connection.execute(%q{SELECT 'commit_test'})
      end
    end
  end

  it 'is included in Transaction classes' do
    expect(ActiveRecord::ConnectionAdapters::RealTransaction).to include(described_class)
    expect(ActiveRecord::ConnectionAdapters::SavepointTransaction).to include(described_class)
  end

  it 'adds a gitlab_schema comment', :aggregate_failures do
    transaction = transaction_klass.new
    transaction.add_gitlab_schema('_test_gitlab_schema')

    recorder = ActiveRecord::QueryRecorder.new do
      transaction.materialize!
      transaction.commit
    end

    expect(recorder.log).to include(
      /materialize_test.*gitlab_schema:_test_gitlab_schema/,
      /commit_test.*gitlab_schema:_test_gitlab_schema/
    )

    recorder = ActiveRecord::QueryRecorder.new do
      transaction.materialize!
      transaction.rollback
    end

    expect(recorder.log).to include(
      /materialize_test.*gitlab_schema:_test_gitlab_schema/,
      /rollback_test.*gitlab_schema:_test_gitlab_schema/
    )
  end

  it 'does not add a gitlab_schema comment if there is no gitlab_schema' do
    transaction = transaction_klass.new

    recorder = ActiveRecord::QueryRecorder.new do
      transaction.materialize!
      transaction.commit
    end

    expect(recorder.log).to include(
      /materialize_test/,
      /commit_test/
    )

    expect(recorder.log).not_to include(
      /gitlab_schema/,
      /gitlab_schema/
    )
  end

  context 'CROSS_DB_MOD_DEBUG is enabled' do
    before do
      stub_env('CROSS_DB_MOD_DEBUG', '1')
    end

    it 'logs to Rails log' do
      transaction = transaction_klass.new
      transaction.add_gitlab_schema('_test_gitlab_schema')

      allow(Rails.logger).to receive(:debug).and_call_original
      expect(Rails.logger).to receive(:debug).with(/CrossDatabaseModification gitlab_schema:  --> _test_gitlab_schema/).and_call_original

      transaction.materialize!
      transaction.commit
    end
  end
end
