# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Geo::LogCursor::Events::DesignRepositoryUpdatedEvent,
  :clean_gitlab_redis_shared_state,
  feature_category: :geo_replication do
  include ::EE::GeoHelpers

  let_it_be(:secondary) { create(:geo_node) }
  let_it_be(:secondary_excludes_all_projects) { create(:geo_node, :selective_sync_excludes_all_projects) }

  let(:logger) { Gitlab::Geo::LogCursor::Logger.new(described_class, Logger::INFO) }
  let(:project) { create(:project) }
  let(:design_repository_updated_event) { create(:geo_design_repository_updated_event, project: project) }
  let(:event_log) { create(:geo_event_log, repository_updated_event: design_repository_updated_event) }
  let!(:event_log_state) { create(:geo_event_log_state, event_id: event_log.id - 1) }
  let(:sync_worker_class) { ::Geo::DesignRepositorySyncWorker }
  let(:registry_class) { ::Geo::DesignRegistry }
  let(:registry_factory) { :geo_design_registry }
  let(:registry_factory_args) { [:synced, project: project] }
  let(:sync_worker_expected_arg) { project.id }

  subject(:event) { described_class.new(design_repository_updated_event, Time.now, logger) }

  before do
    stub_current_geo_node(secondary)
  end

  describe '#process' do
    context 'when the associated shard is healthy' do
      before do
        allow(Gitlab::ShardHealthCache).to receive(:healthy_shard?).with('default').and_return(true)
      end

      context 'when the design repository is not excluded by selective sync' do
        it_behaves_like 'event should trigger a sync'

        context 'when the project is included in selective sync but there is no design' do
          before do
            node = create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: [project.repository_storage])
            stub_current_geo_node(node)
          end

          context 'when a registry does not yet exist' do
            it_behaves_like 'event does not create a registry'
            it_behaves_like 'event does not schedule a sync worker'
            it_behaves_like 'logs event source info'
          end
        end
      end

      context "when the design repository is excluded by selective sync" do
        before do
          stub_current_geo_node(secondary_excludes_all_projects)
        end

        context 'when a registry does not yet exist' do
          it_behaves_like 'event does not create a registry'
          it_behaves_like 'event does not schedule a sync worker'
          it_behaves_like 'logs event source info'
        end

        # This describes an optimization to avoid double-checking a heavy (330ms
        # is heavy for the log cursor) selective sync query too often:
        # If the registry exists, then we assume it *should* exist. This will
        # usually be accurate. The responsibility falls to proper handling of
        # delete events as well as the `RegistryConsistencyWorker` to remove
        # registries.
        context 'when a registry exists' do
          let!(:registry) { create(registry_factory, *registry_factory_args) }

          it_behaves_like 'event transitions a registry to pending'
          it_behaves_like 'event schedules a sync worker'
          it_behaves_like 'logs event source info'
        end
      end
    end

    context 'when associated shard is unhealthy' do
      before do
        allow(Gitlab::ShardHealthCache).to receive(:healthy_shard?).with('default').and_return(false)
      end

      context 'when a registry does not yet exist' do
        it_behaves_like 'event creates a registry'
        it_behaves_like 'event does not schedule a sync worker'
        it_behaves_like 'logs event source info'
      end

      context 'when a registry exists' do
        let!(:registry) { create(registry_factory, *registry_factory_args) }

        it_behaves_like 'event transitions a registry to pending'
        it_behaves_like 'event does not schedule a sync worker'
        it_behaves_like 'logs event source info'
      end
    end
  end
end
