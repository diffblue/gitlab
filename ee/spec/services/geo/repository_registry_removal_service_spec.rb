# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::RepositoryRegistryRemovalService, feature_category: :geo_replication do
  include EE::GeoHelpers

  let(:snippet_repository_registry) { create(:geo_snippet_repository_registry) }
  let(:snippet_repository) { snippet_repository_registry.snippet_repository }
  let(:replicator) { snippet_repository.replicator }
  let(:params) do
    {
      full_path: snippet_repository.repository.full_path,
      repository_storage: snippet_repository.repository_storage,
      disk_path: snippet_repository.repository.disk_path
    }
  end

  subject(:service) { described_class.new(replicator, params) }

  describe '#execute' do
    before do
      service
      snippet_repository.destroy!
    end

    it 'removes registry record' do
      expect { service.execute }.to change { Geo::SnippetRepositoryRegistry.count }.by(-1)
    end

    it 'removes repository' do
      expect_next_instance_of(Repositories::DestroyService) do |service|
        expect(service).to receive(:execute).and_return({ status: :success })
      end

      service.execute
    end
  end
end
