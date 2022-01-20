# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::CleanupService do
  include ::EE::GeoHelpers

  let(:project) { create(:project, :repository, bfg_object_map: fixture_file_upload('spec/fixtures/bfg_object_map.txt')) }
  let(:object_map) { project.bfg_object_map }
  let(:primary) { create(:geo_node, :primary) }

  subject(:service) { described_class.new(project) }

  describe '#execute' do
    before do
      stub_current_geo_node(primary)
    end

    it 'sends a Geo notification about the update on success' do
      expect_next_instance_of(Geo::RepositoryUpdatedService) do |service|
        expect(service).to receive(:execute)
      end

      service.execute
    end

    it 'does not send a Geo notification if the update fails' do
      object_map.remove!

      expect(Geo::RepositoryUpdatedService).not_to receive(:new)

      expect { service.execute }.to raise_error(/object map/)

      expect(Geo::RepositoryUpdatedEvent.count).to eq(0)
    end
  end
end
