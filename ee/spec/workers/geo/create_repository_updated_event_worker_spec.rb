# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::CreateRepositoryUpdatedEventWorker, feature_category: :geo_replication do
  include ::EE::GeoHelpers
  include AfterNextHelpers

  let_it_be(:primary_site) { create(:geo_node, :primary) }
  let_it_be(:secondary_site) { create(:geo_node) }
  let_it_be(:project) { create(:project, :repository) }

  let(:event) { Repositories::KeepAroundRefsCreatedEvent.new(data: { project_id: project.id }) }

  subject { consume_event(subscriber: described_class, event: event) }

  context 'on a Geo primary site' do
    before do
      stub_current_geo_node(primary_site)
    end

    it_behaves_like 'subscribes to event'

    context 'when geo_project_repository_replication is enabled' do
      it 'consumes the published event', :sidekiq_inline do
        expect_next(described_class)
          .to receive(:handle_event)
          .with(instance_of(event.class))
          .and_call_original

        expect do
          ::Gitlab::EventStore.publish(event)
        end.to change { ::Geo::Event.where(event_name: :updated).count }.by(1)
      end
    end

    context 'when geo_project_repository_replication is disable' do
      before do
        stub_feature_flags(geo_project_repository_replication: false)
      end

      it 'consumes the published event', :sidekiq_inline do
        expect_next(described_class)
          .to receive(:handle_event)
          .with(instance_of(event.class))
          .and_call_original

        expect do
          ::Gitlab::EventStore.publish(event)
        end.to change { ::Geo::RepositoryUpdatedEvent.count }.by(1)
      end
    end
  end

  context 'on a Geo secondary site' do
    it 'does not create a Geo::RepositoryUpdatedEvent' do
      stub_current_geo_node(secondary_site)

      expect { subject }
        .not_to change { ::Geo::RepositoryUpdatedEvent.count }
    end
  end
end
