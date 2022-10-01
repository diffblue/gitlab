# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Geo::LogCursor::Events::ContainerRepositoryUpdatedEvent, :clean_gitlab_redis_shared_state do
  include ::EE::GeoHelpers

  let_it_be(:secondary) { create(:geo_node) }
  let_it_be(:secondary_excludes_all_projects) { create(:geo_node, :selective_sync_excludes_all_projects) }

  let(:logger) { Gitlab::Geo::LogCursor::Logger.new(described_class, Logger::INFO) }
  let(:event_log) { create(:geo_event_log, :container_repository_updated_event) }
  let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log.id - 1) }
  let(:container_repository_updated_event) { event_log.container_repository_updated_event }
  let(:container_repository) { container_repository_updated_event.container_repository }
  let(:sync_worker_class) { ::Geo::ContainerRepositorySyncWorker }
  let(:registry_class) { ::Geo::ContainerRepositoryRegistry }
  let(:registry_factory) { :geo_container_repository_registry }
  let(:registry_factory_args) { [:synced, container_repository: container_repository] }
  let(:sync_worker_expected_arg) { container_repository.id }

  subject(:event) { described_class.new(container_repository_updated_event, Time.now, logger) }

  before do
    stub_current_geo_node(secondary)
  end

  describe '#process' do
    context 'when container repository replication is enabled' do
      before do
        stub_config(geo: { registry_replication: { enabled: true } })
      end

      context "when the container repository is not excluded by selective sync" do
        context 'when a registry does not yet exist' do
          it_behaves_like 'event creates a registry'
          it_behaves_like 'event schedules a sync worker'
          it_behaves_like 'logs event source info'
        end

        context 'when a registry exists' do
          let!(:registry) { create(registry_factory, *registry_factory_args) }

          it_behaves_like 'event schedules a sync worker'
          it_behaves_like 'logs event source info'
        end
      end

      context "when the container repository is excluded by selective sync" do
        before do
          stub_current_geo_node(secondary_excludes_all_projects)
        end

        context 'when a registry does not exist' do
          it_behaves_like 'event does not create a registry'
          it_behaves_like 'event does not schedule a sync worker'
          it_behaves_like 'logs event source info'
        end

        context 'when a registry exists' do
          let!(:registry) { create(registry_factory, *registry_factory_args) }

          # This describes an optimization to avoid double-checking a heavy
          # (330ms is heavy for the log cursor) selective sync query too often:
          # If the registry exists, then we assume it *should* exist. This will
          # usually be accurate. The responsibility falls to proper handling of
          # delete events as well as the `RegistryConsistencyWorker` to remove
          # registries.
          it_behaves_like 'event schedules a sync worker'
          it_behaves_like 'logs event source info'
        end
      end
    end

    context 'when container repository replication is disabled' do
      before do
        stub_config(geo: { registry_replication: { enabled: false } })
      end

      context 'when a registry does not exist' do
        it_behaves_like 'event does not create a registry'
        it_behaves_like 'event does not schedule a sync worker'
        it_behaves_like 'logs event source info'
      end

      context 'when a registry exists' do
        let!(:registry) { create(registry_factory, *registry_factory_args) }

        it_behaves_like 'event does not schedule a sync worker'
        it_behaves_like 'logs event source info'
      end
    end
  end
end
