# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::CreateRepositoryUpdatedEventWorker, feature_category: :geo_replication do
  include ::EE::GeoHelpers

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
  end

  context 'on a Geo secondary site' do
    it 'does not create a Geo::RepositoryUpdatedEvent' do
      stub_current_geo_node(secondary_site)

      expect { subject }
        .not_to change { ::Geo::RepositoryUpdatedEvent.count }
    end
  end
end
