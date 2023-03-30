# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectImportState, type: :model, feature_category: :importers do
  include ::EE::GeoHelpers

  let_it_be(:project) { create(:project) }

  describe 'transitions' do
    let(:import_state) { create(:import_state, :started, import_type: :github, project: project) }

    context 'state transition: [:none, :finished, :failed] => :scheduled' do
      let(:import_state) { create(:import_state, :failed, import_type: :github, project: project) }
      let(:jid) { '551d3ceac5f67a116719ce41' }

      before do
        allow(import_state.project).to receive(:add_import_job).and_return(jid)
        allow(Gitlab::Mirror).to receive(:increment_capacity).with(import_state.project_id)
      end

      it 'calls project import job and sets last_update_scheduled_at' do
        import_state.schedule

        expect(Gitlab::Mirror).not_to have_received(:increment_capacity)
        expect(import_state.project).to have_received(:add_import_job)
        expect(import_state.jid).to eq jid
        expect(import_state.last_update_scheduled_at).to be_within(1.second).of(Time.current)
      end

      context 'when project mirrored' do
        let(:mirror_project) { create(:project) }
        let(:import_state) { create(:import_state, :failed, :mirror, import_type: :github, project: mirror_project) }

        it 'increments mirror capacity' do
          import_state.schedule

          expect(Gitlab::Mirror).to have_received(:increment_capacity)
          expect(import_state.project).to have_received(:add_import_job)
          expect(import_state.jid).to eq jid
          expect(import_state.last_update_scheduled_at).to be_within(1.second).of(Time.current)
        end
      end
    end

    context 'state transition: [:started] => [:finished]' do
      context 'Geo repository update events' do
        let(:repository_updated_service) { instance_double('::Geo::RepositoryUpdatedService') }
        let(:wiki_updated_service) { instance_double('::Geo::RepositoryUpdatedService') }
        let(:design_updated_service) { instance_double('::Geo::RepositoryUpdatedService') }

        before do
          allow(::Geo::RepositoryUpdatedService)
            .to receive(:new)
            .with(project.repository)
            .and_return(repository_updated_service)

          allow(::Geo::RepositoryUpdatedService)
            .to receive(:new)
            .with(project.wiki.repository)
            .and_return(wiki_updated_service)

          allow(::Geo::RepositoryUpdatedService)
            .to receive(:new)
            .with(project.design_repository)
            .and_return(design_updated_service)
        end

        context 'with geo_project_wiki_repository_replication feature flag disabled' do
          before do
            stub_feature_flags(geo_project_wiki_repository_replication: false)
          end

          it 'calls Geo::RepositoryUpdatedService when running on a Geo primary node', :aggregate_failures do
            stub_primary_node

            expect(repository_updated_service).to receive(:execute).once
            expect(wiki_updated_service).to receive(:execute).once
            expect(design_updated_service).to receive(:execute).once

            import_state.finish
          end

          it 'does not call Geo::RepositoryUpdatedService when not running on a Geo primary node', :aggregate_failures do
            stub_secondary_node

            expect(repository_updated_service).not_to receive(:execute)
            expect(wiki_updated_service).not_to receive(:execute)
            expect(design_updated_service).not_to receive(:execute)

            import_state.finish
          end
        end

        context 'with geo_project_wiki_repository_replication feature flag enabled' do
          before do
            stub_feature_flags(geo_project_wiki_repository_replication: true)
          end

          context 'when on a Geo primary site' do
            before do
              stub_primary_node
            end

            it 'does not call Geo::RepositoryUpdatedService for the wiki repository', :aggregate_failures do
              expect(repository_updated_service).to receive(:execute).once
              expect_next_instance_of(::Geo::RepositoryUpdatedService, project.wiki.repository).never
              expect(design_updated_service).to receive(:execute)

              import_state.finish
            end

            context 'when wiki_repository does not exist' do
              it 'does not call replicator to update Geo' do
                expect(project.wiki_repository).to be_nil
                expect(repository_updated_service).to receive(:execute).once
                expect(design_updated_service).to receive(:execute).once
                expect_next_instance_of(Geo::ProjectWikiRepositoryReplicator).never

                import_state.finish
              end
            end

            context 'when wiki_repository exists' do
              it 'calls replicator to update Geo', :aggregate_failures do
                create(:project_wiki_repository, project: project)

                expect(project.wiki_repository).to be_present
                expect(repository_updated_service).to receive(:execute).once
                expect(design_updated_service).to receive(:execute).once
                expect(project.wiki_repository.replicator).to receive(:handle_after_update)

                import_state.finish
              end
            end
          end
        end
      end

      context 'elasticsearch indexing disabled for this project' do
        before do
          expect(project).to receive(:use_elasticsearch?).and_return(false)
        end

        it 'does not index the repository' do
          expect(ElasticCommitIndexerWorker).not_to receive(:perform_async)

          import_state.finish
        end
      end

      context 'elasticsearch indexing enabled for this project' do
        before do
          expect(project).to receive(:use_elasticsearch?).and_return(true)
        end

        context 'no index status' do
          it 'schedules a full index of the repository' do
            expect(ElasticCommitIndexerWorker).to receive(:perform_async).with(import_state.project_id)

            import_state.finish
          end
        end

        context 'with index status' do
          let(:index_status) { IndexStatus.create!(project: project, indexed_at: Time.current, last_commit: 'foo') }

          it 'schedules a full index of the repository' do
            expect(ElasticCommitIndexerWorker).to receive(:perform_async).with(import_state.project_id)

            import_state.finish
          end
        end
      end
    end
  end

  describe 'when create' do
    it 'sets next execution timestamp to now' do
      travel_to(Time.current) do
        import_state = create(:import_state, :mirror)

        expect(import_state.next_execution_timestamp).to be_like_time(Time.current)
      end
    end
  end

  describe '#in_progress?' do
    let(:traits) { [] }
    let(:import_state) { create(:import_state, *traits, import_url: Project::UNKNOWN_IMPORT_URL) }

    shared_examples 'import in progress' do |status|
      context 'when project is not a mirror and repository is empty' do
        let(:traits) { [status] }

        it 'returns true' do
          expect(import_state.in_progress?).to be_truthy
        end
      end

      context 'when project is a mirror' do
        let(:traits) { [status, :mirror] }

        context 'when repository is empty' do
          it 'returns true' do
            expect(import_state.in_progress?).to be_truthy
          end
        end
      end

      context 'when repository is not empty' do
        let(:traits) { [status, :repository] }

        it 'returns true' do
          expect(import_state.in_progress?).to be_truthy
        end
      end

      context 'when project is a mirror and repository is not empty' do
        let(:traits) { [status, :mirror, :repository] }

        it 'returns false' do
          expect(import_state.in_progress?).to be_falsey
        end
      end
    end

    context 'when import status is scheduled' do
      it_behaves_like 'import in progress', :scheduled
    end

    context 'when import status is started' do
      it_behaves_like 'import in progress', :started
    end

    context 'when import status is finished' do
      let(:traits) { [:finished] }

      it 'returns false' do
        expect(import_state.in_progress?).to be_falsey
      end
    end
  end

  describe 'hard failing a mirror' do
    it 'sends a notification' do
      import_state = create(:import_state, :mirror, :started, retry_count: Gitlab::Mirror::MAX_RETRY)

      expect_any_instance_of(EE::NotificationService).to receive(:mirror_was_hard_failed).with(import_state.project)

      import_state.fail_op
    end
  end

  describe 'mirror has an unrecoverable failure' do
    let(:import_state) { create(:import_state, :mirror, :started, last_error: 'SSL certificate problem: certificate has expired') }

    it 'sends a notification' do
      expect_any_instance_of(EE::NotificationService).to receive(:mirror_was_hard_failed).with(import_state.project)

      import_state.fail_op
    end

    it 'marks import state as hard_failed' do
      import_state.fail_op

      expect(import_state.hard_failed?).to be_truthy
    end

    it 'does not set next execution timestamp' do
      expect { import_state.fail_op }.not_to change { import_state.next_execution_timestamp }
    end
  end

  describe '#mirror_waiting_duration' do
    let(:import_state) { create(:import_state, :scheduled, :mirror) }

    it 'returns in seconds the time spent in the queue' do
      import_state.last_update_started_at = import_state.last_update_scheduled_at + 5.minutes

      expect(import_state.mirror_waiting_duration).to eq(300)
    end

    context 'when account does not have a license' do
      before do
        stub_licensed_features(repository_mirrors: false)
      end

      it 'returns in seconds the time spent in the queue' do
        import_state.last_update_started_at = import_state.last_update_scheduled_at + 1.minute

        expect(import_state.mirror_waiting_duration).to eq(60)
      end
    end

    context 'when import state is not mirror' do
      let(:import_state) { create(:import_state, :scheduled) }

      it { expect(import_state.mirror_waiting_duration).to be_nil }
    end
  end

  describe '#mirror_update_duration' do
    let(:import_state) { create(:import_state, :started, :mirror) }

    it 'returns in seconds the time spent updating' do
      import_state.last_update_at = import_state.last_update_started_at + 5.minutes

      expect(import_state.mirror_update_duration).to eq(300)
    end

    context 'when account does not have a license' do
      before do
        stub_licensed_features(repository_mirrors: false)
      end

      it 'returns in seconds the time spent in the queue' do
        import_state.last_update_at = import_state.last_update_started_at + 1.minute

        expect(import_state.mirror_update_duration).to eq(60)
      end
    end

    context 'when import state is not mirror' do
      let(:import_state) { create(:import_state, :scheduled) }

      it { expect(import_state.mirror_update_duration).to be_nil }
    end
  end

  describe '#updating_mirror?' do
    shared_examples 'updating mirror' do |status|
      context 'with repository' do
        it 'returns false' do
          import_state = create(:import_state, status, :repository)

          expect(import_state.updating_mirror?).to be_falsey
        end
      end

      context 'with mirror' do
        it 'returns false' do
          import_state = create(:import_state, status, :mirror)

          expect(import_state.updating_mirror?).to be_falsey
        end
      end

      context 'with mirror and repository' do
        it 'returns false' do
          import_state = create(:import_state, status, :mirror, :repository)

          expect(import_state.updating_mirror?).to be_truthy
        end
      end
    end

    context 'when scheduled' do
      it_behaves_like 'updating mirror', :scheduled
    end

    context 'when started' do
      it_behaves_like 'updating mirror', :started
    end
  end

  describe '#mirror_update_due?' do
    context 'when mirror is expected to run soon' do
      it 'returns true' do
        import_state = create(:import_state,
                              :finished,
                              :mirror,
                              :repository,
                              next_execution_timestamp: Time.current - 2.minutes)

        expect(import_state.mirror_update_due?).to be true
      end
    end

    context 'when the project is archived' do
      let(:import_state) do
        create(:import_state,
               :finished,
               :mirror,
               :repository,
               next_execution_timestamp: Time.current - 2.minutes)
      end

      before do
        import_state.project.update_column(:archived, true)
      end

      it 'returns false' do
        expect(import_state.mirror_update_due?).to be false
      end
    end

    context 'when the project pending_delete' do
      let(:import_state) do
        create(:import_state,
               :finished,
               :mirror,
               :repository,
               next_execution_timestamp: Time.current - 2.minutes)
      end

      it 'returns false' do
        import_state.project.update_column(:pending_delete, true)

        expect(import_state.mirror_update_due?).to be false
      end
    end

    context 'when mirror has no content' do
      it 'returns false' do
        import_state = create(:import_state, :finished, :mirror)
        import_state.next_execution_timestamp = Time.current - 2.minutes

        expect(import_state.mirror_update_due?).to be false
      end
    end

    context 'when mirror is hard_failed' do
      it 'returns false' do
        import_state = create(:import_state, :hard_failed, :mirror, :repository)

        expect(import_state.mirror_update_due?).to be false
      end
    end

    context 'mirror is updating' do
      it 'returns false when scheduled' do
        import_state = create(:import_state, :scheduled, :mirror, :repository)

        expect(import_state.mirror_update_due?).to be false
      end
    end

    context 'when next_execution_timestamp is nil' do
      it 'returns false' do
        import_state = create(:import_state, :finished, :mirror, :repository)
        import_state.next_execution_timestamp = nil

        expect(import_state.mirror_update_due?).to be false
      end
    end
  end

  describe '#last_update_status' do
    context 'when not a mirror' do
      it 'returns nil' do
        import_state = create(:import_state)

        expect(import_state.last_update_status).to be_nil
      end
    end

    context 'when mirror' do
      let(:import_state) { create(:import_state, :mirror) }

      context 'when mirror has not updated' do
        it 'returns nil' do
          expect(import_state.last_update_status).to be_nil
        end
      end

      context 'when mirror has updated' do
        let(:timestamp) { Time.current }

        before do
          import_state.last_update_at = timestamp
        end

        context 'when last update time equals the time of the last successful update' do
          it 'returns success' do
            import_state.last_successful_update_at = timestamp

            expect(import_state.last_update_status).to eq(:success)
          end
        end

        context 'when last update time does not equal the time of the last successful update' do
          it 'returns failed' do
            import_state.last_successful_update_at = timestamp - 1.minute

            expect(import_state.last_update_status).to eq(:failed)
          end
        end
      end
    end
  end

  describe '#ever_updated_successfully' do
    it 'returns false when project is not a mirror' do
      import_state = create(:import_state)

      expect(import_state.ever_updated_successfully?).to be_falsey
    end

    context 'when mirror' do
      let(:import_state) { create(:import_state, :mirror) }

      it 'returns false when project never updated' do
        expect(import_state.ever_updated_successfully?).to be_falsey
      end

      it 'returns false when first update failed' do
        import_state.last_update_at = Time.current

        expect(import_state.ever_updated_successfully?).to be_falsey
      end

      it 'returns true when a successful update timestamp exists' do
        # It does not matter if the last update was successful or not
        import_state.last_update_at = Time.current
        import_state.last_successful_update_at = Time.current - 5.minutes

        expect(import_state.ever_updated_successfully?).to be_truthy
      end
    end
  end

  describe '#set_next_execution_timestamp' do
    let(:import_state) { create(:import_state, :mirror, :finished) }
    let!(:timestamp) { Time.current.change(usec: 0) }
    let!(:jitter) { 2.seconds }

    before do
      allow_any_instance_of(ProjectImportState).to receive(:rand).and_return(jitter)
    end

    context 'when base delay is lower than mirror_max_delay' do
      before do
        import_state.last_update_started_at = timestamp - 2.minutes
      end

      context 'when retry count is 0' do
        it 'applies transition successfully' do
          expect_next_execution_timestamp(import_state, timestamp + 52.minutes)
        end
      end

      context 'when incrementing retry count' do
        it 'applies transition successfully' do
          import_state.retry_count = 2
          import_state.increment_retry_count

          expect_next_execution_timestamp(import_state, timestamp + 156.minutes)
        end
      end
    end

    context 'when boundaries are surpassed' do
      let!(:mirror_jitter) { 30.seconds }

      before do
        allow(Gitlab::Mirror).to receive(:rand).and_return(mirror_jitter)
      end

      context 'when last_update_started_at is nil' do
        it 'applies transition successfully' do
          expect_next_execution_timestamp(import_state, timestamp + 30.minutes + mirror_jitter)
        end
      end

      context 'when base delay is lower than mirror min_delay' do
        before do
          import_state.last_update_started_at = timestamp - 1.second
        end

        context 'when resetting retry count' do
          it 'applies transition successfully' do
            expect_next_execution_timestamp(import_state, timestamp + 30.minutes + mirror_jitter)
          end
        end

        context 'when incrementing retry count' do
          it 'applies transition successfully' do
            import_state.retry_count = 3
            import_state.increment_retry_count

            expect_next_execution_timestamp(import_state, timestamp + 122.minutes)
          end
        end
      end

      context 'when base delay is higher than mirror_max_delay' do
        let(:max_timestamp) { timestamp + Gitlab::CurrentSettings.mirror_max_delay.minutes }

        before do
          import_state.last_update_started_at = timestamp - 1.hour
        end

        context 'when resetting retry count' do
          it 'applies transition successfully' do
            expect_next_execution_timestamp(import_state, max_timestamp + mirror_jitter)
          end
        end

        context 'when incrementing retry count' do
          it 'applies transition successfully' do
            import_state.retry_count = 2
            import_state.increment_retry_count

            expect_next_execution_timestamp(import_state, max_timestamp + mirror_jitter)
          end
        end
      end
    end

    def expect_next_execution_timestamp(import_state, new_timestamp)
      travel_to(timestamp) do
        expect do
          import_state.set_next_execution_timestamp
        end.to change { import_state.next_execution_timestamp }.to eq(new_timestamp)
      end
    end
  end

  describe '#force_import_job!' do
    it 'returns nil if mirror is about to update' do
      import_state = create(:import_state,
                            :repository,
                            :mirror,
                            next_execution_timestamp: Time.current - 2.minutes)

      expect(import_state.force_import_job!).to be_nil
    end

    it 'returns nil when mirror is updating' do
      import_state = create(:import_state, :repository, :mirror, :started)

      expect(import_state.force_import_job!).to be_nil
    end

    it 'sets next execution timestamp to 5 minutes ago and schedules UpdateAllMirrorsWorker' do
      timestamp = Time.current
      import_state = create(:import_state, :mirror)

      expect(UpdateAllMirrorsWorker).to receive(:perform_async)

      travel_to(timestamp) do
        expect { import_state.force_import_job! }.to change(import_state, :next_execution_timestamp).to(5.minutes.ago)
      end
    end

    context 'when mirror is hard failed' do
      it 'resets retry count and schedules a mirroring worker' do
        timestamp = Time.current
        import_state = create(:import_state, :mirror, :hard_failed)

        expect(UpdateAllMirrorsWorker).to receive(:perform_async)

        travel_to(timestamp) do
          expect { import_state.force_import_job! }.to change(import_state, :retry_count).to(0)
          expect(import_state.next_execution_timestamp).to be_like_time(5.minutes.ago)
        end
      end
    end
  end

  describe '#reset_retry_count' do
    let(:import_state) { create(:import_state, :mirror, :finished, retry_count: 3) }

    it 'resets retry_count to 0' do
      expect { import_state.reset_retry_count }.to change { import_state.retry_count }.from(3).to(0)
    end
  end

  describe '#increment_retry_count' do
    let(:import_state) { create(:import_state, :mirror, :finished) }

    it 'increments retry_count' do
      expect { import_state.increment_retry_count }.to change { import_state.retry_count }.from(0).to(1)
    end
  end

  describe '#set_max_retry_count' do
    let(:import_state) { create(:import_state, :mirror, :failed) }

    it 'sets retry_count to max' do
      expect { import_state.set_max_retry_count }.to change { import_state.retry_count }.from(0).to(Gitlab::Mirror::MAX_RETRY + 1)
    end
  end

  describe '#unrecoverable_failure?' do
    subject { import_state.unrecoverable_failure? }

    let(:import_state) { create(:import_state, :mirror, :failed, last_error: last_error) }
    let(:last_error) { 'fetch remote: "fatal: unable to access \'https://expired_cert.host\': SSL certificate problem: certificate has expired\n": exit status 128' }

    it { is_expected.to be_truthy }

    context 'when error is recoverable' do
      let(:last_error) { 'fetch remote: "fatal: unable to access \'host\': Failed to connect to host port 80: Connection timed out\n": exit status 128' }

      it { is_expected.to be_falsey }
    end

    context 'when error is missing' do
      let(:last_error) { nil }

      it { is_expected.to be_falsey }
    end

    context 'when import_state is not failed' do
      let(:import_state) { create(:import_state, :mirror, :finished, last_error: last_error) }

      it { is_expected.to be_falsey }
    end
  end
end
