# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Geo::HealthCheck, :geo, feature_category: :geo_replication do
  include ::EE::GeoHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:secondary) { create(:geo_node) }

  describe '#perform_checks' do
    before do
      stub_current_geo_node(secondary)
    end

    context 'when an exception is raised' do
      it 'catches the exception nicely and returns the message' do
        allow(Gitlab::Geo).to receive(:secondary?).and_raise('Uh oh')

        expect(subject.perform_checks).to eq('Uh oh')
      end
    end

    context 'with PostgreSQL' do
      context 'on the primary node' do
        it 'returns an empty string' do
          allow(Gitlab::Geo).to receive(:secondary?) { false }

          expect(subject.perform_checks).to be_blank
        end
      end

      context 'on the secondary node' do
        let(:geo_database_configured) { true }
        let(:db_read_only) { true }

        before do
          allow(Gitlab::Geo).to receive(:secondary?) { true }
          allow(Gitlab::Geo).to receive(:geo_database_configured?) { geo_database_configured }
          allow(ApplicationRecord.database).to receive(:db_read_only?) { db_read_only }
        end

        context 'when the Geo tracking DB is not configured' do
          let(:geo_database_configured) { false }

          it 'returns an error' do
            expect(subject.perform_checks).to include('Geo database configuration file is missing')
          end
        end

        context 'when reusing an existing tracking database' do
          it 'returns an error when event_log_state is older than current node created_at' do
            create(:geo_event_log_state, created_at: 3.months.ago)

            expect(subject.perform_checks).to include('An existing tracking database cannot be reused.')
          end
        end

        context 'when the database is writable' do
          let(:db_read_only) { false }

          it 'returns an error' do
            expect(subject.perform_checks).to include('Geo node has a database that is writable which is an indication it is not configured for replication with the primary node.')
          end
        end

        context 'streaming replication' do
          it 'returns an error when replication is not working' do
            allow(ActiveRecord::Base).to receive_message_chain('connection.execute').with(no_args).with('SELECT * FROM pg_last_wal_receive_lsn() as result').and_return(['result' => 'fake'])
            allow(ActiveRecord::Base).to receive_message_chain('connection.select_values').with(no_args).with('SELECT pid FROM pg_stat_wal_receiver').and_return([])

            expect(subject.perform_checks).to match(/Geo node does not appear to be replicating the database from the primary node/)
          end
        end

        context 'archive recovery replication' do
          it 'returns an error when replication is not working' do
            allow(subject).to receive(:streaming_replication_enabled?).and_return(false)
            allow(subject).to receive(:archive_recovery_replication_enabled?).and_return(true)
            allow(ActiveRecord::Base).to receive_message_chain('connection.execute').with(no_args).with('SELECT * FROM pg_last_xact_replay_timestamp() as result').and_return([{ 'result' => nil }])

            expect(subject.perform_checks).to match(/Geo node does not appear to be replicating the database from the primary node/)
          end
        end

        context 'some sort of replication' do
          before do
            allow(subject).to receive(:replication_enabled?).and_return(true)
          end

          context 'that is not working' do
            it 'returns an error' do
              allow(subject).to receive(:archive_recovery_replication_enabled?).and_return(false)
              allow(subject).to receive(:streaming_replication_enabled?).and_return(false)

              expect(subject.perform_checks).to match(/Geo node does not appear to be replicating the database from the primary node/)
            end
          end

          context 'that is working' do
            before do
              allow(subject).to receive(:replication_working?).and_return(true)
            end

            it 'returns an error if database is not fully migrated' do
              allow(subject).to receive(:database_version).and_return('20170101')
              allow(subject).to receive(:migration_version).and_return('20170201')

              message = subject.perform_checks

              expect(message).to include('Geo database version (20170101) does not match latest migration (20170201)')
              expect(message).to include('gitlab-rake db:migrate:geo')
            end

            it 'finally returns an empty string when everything is healthy' do
              expect(subject.perform_checks).to be_blank
            end
          end
        end
      end
    end
  end

  describe '#db_replication_lag_seconds' do
    before do
      query = 'SELECT CASE WHEN pg_last_wal_receive_lsn() = pg_last_wal_replay_lsn() THEN 0 ELSE EXTRACT (EPOCH FROM now() - pg_last_xact_replay_timestamp())::INTEGER END AS replication_lag'
      allow(ApplicationRecord.database).to receive(:pg_last_wal_receive_lsn).and_return('pg_last_wal_receive_lsn')
      allow(ApplicationRecord.database).to receive(:pg_last_wal_replay_lsn).and_return('pg_last_wal_replay_lsn')
      allow(ActiveRecord::Base).to receive_message_chain('connection.execute').with(query).and_return([{ 'replication_lag' => lag_in_seconds }])
    end

    context 'when there is no lag' do
      let(:lag_in_seconds) { nil }

      it 'returns 0 seconds' do
        expect(subject.db_replication_lag_seconds).to eq(0)
      end
    end

    context 'when there is lag' do
      let(:lag_in_seconds) { 7 }

      it 'returns the number of seconds' do
        expect(subject.db_replication_lag_seconds).to eq(7)
      end
    end
  end

  describe '#replication_enabled?' do
    where(:streaming_replication_enabled, :archive_recovery_replication_enabled, :result) do
      false | false | false
      true  | false | true
      false | true  | true
    end

    with_them do
      before do
        allow(subject).to receive(:streaming_replication_enabled?).and_return(streaming_replication_enabled)
        allow(subject).to receive(:archive_recovery_replication_enabled?).and_return(archive_recovery_replication_enabled)
      end

      it 'returns the correct result' do
        expect(subject.replication_enabled?).to eq(result)
      end
    end
  end

  describe '#replication_working?' do
    where(:streaming_replication_enabled, :streaming_replication_active, :some_replication_active, :result) do
      false | nil   | false | false
      false | nil   | true  | true
      true  | false | nil   | false
      true  | true  | nil   | true
    end

    with_them do
      before do
        allow(subject).to receive(:streaming_replication_enabled?).and_return(streaming_replication_enabled)
        allow(subject).to receive(:streaming_replication_active?).and_return(streaming_replication_active)
        allow(subject).to receive(:some_replication_active?).and_return(some_replication_active)
      end

      it 'returns the correct result' do
        expect(subject.replication_working?).to eq(result)
      end
    end
  end
end
