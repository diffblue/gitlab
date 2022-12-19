# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'gitlab:geo rake tasks', :geo, :silence_stdout, feature_category: :geo_replication do
  include ::EE::GeoHelpers

  before do
    Rake.application.rake_require 'tasks/gitlab/geo'
    # We disable the transaction_open? check because Gitlab::Database::BatchCounter.batch_count
    # is not allowed within a transaction but all RSpec tests run inside of a transaction.
    stub_batch_counter_transaction_open_check
    stub_licensed_features(geo: true)
  end

  describe 'gitlab:geo:check_replication_verification_status' do
    let(:run_task) { run_rake_task('gitlab:geo:check_replication_verification_status') }
    let!(:current_node) { create(:geo_node) }
    let!(:geo_node_status) { build(:geo_node_status, :healthy, geo_node: current_node) }

    around do |example|
      example.run
    rescue SystemExit
    end

    before do
      allow(GeoNodeStatus).to receive(:current_node_status).and_return(geo_node_status)
      allow(Gitlab.config.geo.registry_replication).to receive(:enabled).and_return(true)

      allow(Gitlab::Geo::GeoNodeStatusCheck).to receive(:replication_verification_complete?)
                                                  .and_return(complete)
    end

    context 'when replication is up-to-date' do
      let(:complete) { true }

      it 'prints a success message' do
        expect { run_task }.to output(/SUCCESS - Replication is up-to-date/).to_stdout
      end
    end

    context 'when replication is not up-to-date' do
      let(:complete) { false }

      it 'prints an error message' do
        expect { run_task }.to output(/ERROR - Replication is not up-to-date/).to_stdout
      end

      it 'exits with a 1' do
        expect { run_task }.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
      end
    end
  end

  describe 'gitlab:geo:check_database_replication_working' do
    let(:run_task) do
      run_rake_task('gitlab:geo:check_database_replication_working')
    end

    before do
      stub_secondary_node
    end

    context 'when DB replication is enabled' do
      let(:enabled) { true }

      before do
        allow_next_instance_of(Gitlab::Geo::HealthCheck) do |health_check|
          allow(health_check).to receive(:replication_enabled?).and_return(enabled)
          allow(health_check).to receive(:replication_working?).and_return(working)
        end
      end

      context 'when DB replication is working' do
        let(:working) { true }

        it 'prints a success message' do
          expect { run_task }.to output(/SUCCESS - Database replication is working/).to_stdout
        end
      end

      context 'when DB replication is not working' do
        let(:working) { false }

        it 'exits with non-success code' do
          expect { run_task }.to abort_execution.with_message(/ERROR - Database replication is enabled, but not working/)
        end
      end
    end

    context 'when DB replication is not enabled' do
      let(:enabled) { false }

      before do
        allow_next_instance_of(Gitlab::Geo::HealthCheck) do |health_check|
          allow(health_check).to receive(:replication_enabled?).and_return(enabled)
        end
      end

      it 'exits with non-success code' do
        expect { run_task }.to abort_execution.with_message(/ERROR - Database replication is not enabled/)
      end
    end
  end
end
