# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::DesignRepositorySyncWorker, :geo, feature_category: :geo_replication do
  describe '#perform' do
    it 'runs DesignRepositorySyncService' do
      project = create(:project)
      service = spy(:service)

      expect(Geo::DesignRepositorySyncService).to receive(:new).with(project).and_return(service)

      described_class.new.perform(project.id)

      expect(service).to have_received(:execute)
    end

    it 'logs error when repository does not exist' do
      worker = described_class.new

      expect(worker).to receive(:log_error)
        .with("Couldn't find project, skipping syncing", project_id: 20)

      expect(Geo::DesignRepositorySyncService).not_to receive(:new)

      worker.perform(20)
    end
  end
end
