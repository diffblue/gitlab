# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::ProjectHousekeepingService, feature_category: :geo_replication do
  include ExclusiveLeaseHelpers
  include ::EE::GeoHelpers

  subject(:service) { described_class.new(project) }

  let_it_be(:project) { create(:project, :repository) }

  let(:registry) { service.registry }

  before do
    registry.reset_syncs_since_gc!
  end

  after do
    registry.reset_syncs_since_gc!
  end

  describe '#execute' do
    it 'executes housekeeping when conditions are fulfilled' do
      allow(service).to receive(:needed?) { true }

      expect(service).to receive(:do_housekeeping)

      service.execute
    end

    it 'does not execute housekeeping when conditions are not fulfilled' do
      allow(service).to receive(:needed?) { false }

      expect(service).not_to receive(:do_housekeeping)

      service.execute
    end

    it 'resets counter when syncs_since_gc > gc_period' do
      allow(service).to receive(:gc_period).and_return(1)
      allow(service).to receive(:try_obtain_lease).and_return(:the_uuid)
      service.increment!

      Sidekiq::Testing.inline! do
        expect { service.execute }.to change { registry.syncs_since_gc }.to(0)
      end
    end

    context 'task type' do
      it 'goes through all three housekeeping tasks, executing only the highest task when there is overlap' do
        allow(service).to receive(:lease_key).and_return(:the_lease_key)
        stub_exclusive_lease(:the_lease_key, :the_uuid)

        # At fetch 200
        expect(::Projects::GitGarbageCollectWorker).to receive(:perform_async).with(project.id, :gc, :the_lease_key, :the_uuid)
          .once
        # At fetch 50, 100, 150
        expect(::Projects::GitGarbageCollectWorker).to receive(:perform_async).with(project.id, :full_repack, :the_lease_key, :the_uuid)
          .exactly(3).times
        # At fetch 10, 20, ... (except those above)
        expect(::Projects::GitGarbageCollectWorker).to receive(:perform_async).with(project.id, :incremental_repack, :the_lease_key, :the_uuid)
          .exactly(16).times

        201.times do
          service.execute
        end

        expect(registry.syncs_since_gc).to eq(1)
      end
    end

    context 'new repository' do
      subject(:service) { described_class.new(project, new_repository: true) }

      it 'runs gc for a new repository' do
        allow(service).to receive(:lease_key).and_return(:the_lease_key)
        stub_exclusive_lease(:the_lease_key, :the_uuid)

        expect(::Projects::GitGarbageCollectWorker).to receive(:perform_async).with(project.id, :gc, :the_lease_key, :the_uuid).once

        service.execute
      end
    end

    context 'non-new repository' do
      subject(:service) { described_class.new(project, new_repository: false) }

      it 'does not run gc for a non-new repository' do
        stub_exclusive_lease(:the_lease_key, :the_uuid)

        expect(::Projects::GitGarbageCollectWorker).not_to receive(:perform_async)

        service.execute
      end
    end
  end

  describe 'do_housekeeping' do
    context 'when no lease can be obtained' do
      before do
        expect(service).to receive(:try_obtain_lease).and_return(false)
      end

      it 'does not enqueue a job' do
        expect(::Projects::GitGarbageCollectWorker).not_to receive(:perform_async)

        expect(service.send(:do_housekeeping)).to be_falsey
      end

      it 'does not reset syncs_since_gc' do
        allow(service).to receive(:try_obtain_lease).and_return(false)
        allow(service).to receive(:increment!)

        expect { service.send(:do_housekeeping) }.not_to change { registry.syncs_since_gc }
      end
    end

    it 'enqueues a sidekiq job' do
      expect(service).to receive(:try_obtain_lease).and_return(:the_uuid)
      expect(service).to receive(:lease_key).and_return(:the_lease_key)
      expect(service).to receive(:task).and_return(:incremental_repack)
      expect(::Projects::GitGarbageCollectWorker).to receive(:perform_async).with(project.id, :incremental_repack, :the_lease_key, :the_uuid).and_call_original

      Sidekiq::Testing.fake! do
        expect { service.send(:do_housekeeping) }.to change(::Projects::GitGarbageCollectWorker.jobs, :size).by(1)
      end
    end

    it 'does not create object pool' do
      expect(project).not_to receive(:create_object_pool_on_secondary)

      service.send(:do_housekeeping)
    end
  end

  describe '#needed?' do
    it 'when the count is low enough' do
      expect(service.needed?).to eq(false)
    end

    it 'when the count is high enough' do
      allow(registry).to receive(:syncs_since_gc).and_return(10)
      expect(service.needed?).to eq(true)
    end

    it 'when its a new repository' do
      service = described_class.new(project, new_repository: true)

      expect(service.needed?).to eq(true)
    end
  end

  describe '#increment!' do
    it 'increments the syncs_since_gc counter' do
      expect { service.increment! }.to change { registry.syncs_since_gc }.by(1)
    end
  end

  describe '#registry' do
    it 'returns a Geo::ProjectRegistry linked to current project' do
      expect(registry).to be_a(Geo::ProjectRegistry)
      expect(registry.project_id).to eq(project.id)
    end
  end

  describe '#create_object_pool_on_secondary' do
    let(:pool) { create(:pool_repository, :ready) }
    let(:project) { create(:project, pool_repository: pool) }
    let!(:secondary) { create(:geo_node) }

    before do
      allow(subject).to receive(:needed?) { true }
      allow(subject).to receive(:task) { :gc }
      allow(subject).to receive(:try_obtain_lease).and_return(:the_uuid)
      allow(subject).to receive(:execute_gitlab_shell_gc).and_return(nil)
      stub_current_geo_node(secondary)
    end

    it 'creates the object pool when source project repository exists' do
      allow(project.pool_repository.source_project_repository).to receive(:exists?).and_return(true)
      allow(project).to receive(:object_pool_missing?).and_return(true)

      expect_any_instance_of(Geo::CreateObjectPoolService).to receive(:execute)

      subject.execute
    end

    it "doesn't create the object pool when the object pool exists" do
      allow(project).to receive(:object_pool_missing?).and_return(false)

      expect_any_instance_of(Geo::CreateObjectPoolService).not_to receive(:execute)

      subject.execute
    end

    it "doesn't create the object pool when the source project repository doesn't exist" do
      allow(project.pool_repository.source_project_repository).to receive(:exists?).and_return(false)

      expect_any_instance_of(Geo::CreateObjectPoolService).not_to receive(:execute)

      subject.execute
    end
  end
end
