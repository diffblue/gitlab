# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::RepositoryRegistrySyncWorker, :geo, feature_category: :geo_replication do
  include ::EE::GeoHelpers

  it_behaves_like 'a framework registry sync worker', :geo_group_wiki_repository_registry, :repos_max_capacity do
    before do
      # rubocop:disable RSpec/AnyInstanceOf
      allow_any_instance_of(::Repository).to receive(:clone_as_mirror).and_return(true)
      allow_any_instance_of(::Repository).to receive(:fetch_as_mirror).and_return(true)
      # rubocop:enable RSpec/AnyInstanceOf
    end
  end

  describe '#max_capacity' do
    let(:secondary) { create(:geo_node) }

    before do
      stub_current_geo_node(secondary)
    end

    context 'when repos_max_capacity is lower than 10' do
      before do
        secondary.update!(container_repositories_max_capacity: 3, files_max_capacity: 6, repos_max_capacity: 7)
      end

      context 'when container repository replication is enabled' do
        before do
          stub_registry_replication_config(enabled: true)
        end

        it 'returns the container_repositories_max_capacity + 1' do
          expect(described_class.new.send(:max_capacity)).to eq(4)
        end
      end

      context 'when container repository replication is disabled' do
        it 'returns 1' do
          expect(described_class.new.send(:max_capacity)).to eq(1)
        end
      end
    end

    context 'when repos_max_capacity is multiple of 10' do
      before do
        secondary.update!(container_repositories_max_capacity: 3, files_max_capacity: 6, repos_max_capacity: 20)
      end

      context 'when container repository replication is enabled' do
        before do
          stub_registry_replication_config(enabled: true)
        end

        it 'returns the capacity based on 1/10 of repos_max_capacity plus container_repositories_max_capacity' do
          expect(described_class.new.send(:max_capacity)).to eq(5)
        end
      end

      context 'when container repository replication is disabled' do
        it 'returns only 1/10 of repos_max_capacity based capacity' do
          expect(described_class.new.send(:max_capacity)).to eq(2)
        end
      end
    end
  end
end
