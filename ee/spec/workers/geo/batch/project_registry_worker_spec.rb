# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::Batch::ProjectRegistryWorker, feature_category: :geo_replication do
  include ::EE::GeoHelpers

  let_it_be(:secondary) { create(:geo_node) }

  before do
    stub_current_geo_node(secondary)
  end

  describe '#perform' do
    let(:range) { [0, registry.id] }

    context 'when operation is :reverify_repositories' do
      let!(:registry) { create(:geo_project_registry, :repository_verified) }

      it 'flags repositories for reverify' do
        Sidekiq::Testing.inline! do
          subject.perform(:reverify_repositories, range)
        end

        expect(registry.reload.repository_verification_pending?).to be_truthy
      end
    end

    context 'when operation is :resync_repositories' do
      let!(:registry) { create(:geo_project_registry, :synced) }

      it 'flags repositories for resync' do
        Sidekiq::Testing.inline! do
          subject.perform(:resync_repositories, range)
        end

        expect(registry.reload.resync_repository?).to be_truthy
      end
    end

    context 'when informed operation is unknown/invalid' do
      let(:range) { [1, 10] }

      it 'fails with ArgumentError' do
        expect { subject.perform(:unknown_operation, range) }.to raise_error(ArgumentError)
      end
    end
  end
end
