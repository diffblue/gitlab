# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::Batch::ProjectRegistrySchedulerWorker, feature_category: :geo_replication do
  include ExclusiveLeaseHelpers
  include ::EE::GeoHelpers

  let_it_be(:secondary) { create(:geo_node) }

  let(:lease_key) { subject.lease_key }
  let(:lease_timeout) { 2.minutes }

  before do
    stub_current_geo_node(secondary)
    stub_exclusive_lease(renew: true)
  end

  describe '#perform' do
    context 'when operation is :reverify_repositories' do
      let!(:registry) { create(:geo_project_registry, :repository_verified) }

      it 'schedules batches of repositories for reverify' do
        Sidekiq::Testing.fake! do
          expect { subject.perform(:reverify_repositories) }.to change(Geo::Batch::ProjectRegistryWorker.jobs, :size).by(1)
          expect(Geo::Batch::ProjectRegistryWorker.jobs.last['args']).to include('reverify_repositories')
        end
      end

      it 'does nothing if exclusive lease is already acquired' do
        stub_exclusive_lease_taken(lease_key, timeout: lease_timeout)

        Sidekiq::Testing.fake! do
          expect { subject.perform(:reverify_repositories) }.not_to change(Geo::Batch::ProjectRegistryWorker.jobs, :size)
        end
      end
    end

    context 'when operation is :resync_repositories' do
      let!(:registry) { create(:geo_project_registry, :synced) }

      it 'schedules batches of repositories for resync' do
        Sidekiq::Testing.fake! do
          expect { subject.perform(:resync_repositories) }.to change(Geo::Batch::ProjectRegistryWorker.jobs, :size).by(1)
          expect(Geo::Batch::ProjectRegistryWorker.jobs.last['args']).to include('resync_repositories')
        end
      end

      it 'does nothing if exclusive lease is already acquired' do
        stub_exclusive_lease_taken(lease_key, timeout: lease_timeout)

        Sidekiq::Testing.fake! do
          expect { subject.perform(:resync_repositories) }.not_to change(Geo::Batch::ProjectRegistryWorker.jobs, :size)
        end
      end
    end

    context 'when informed operation is unknown/invalid' do
      it 'fails with ArgumentError' do
        expect { subject.perform(:unknown_operation) }.to raise_error(ArgumentError)
      end
    end
  end
end
