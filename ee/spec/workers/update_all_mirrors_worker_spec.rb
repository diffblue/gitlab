# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UpdateAllMirrorsWorker do
  include ExclusiveLeaseHelpers

  subject(:worker) { described_class.new }

  before do
    stub_exclusive_lease
  end

  it_behaves_like 'worker with data consistency',
                  described_class,
                  feature_flag: :load_balancing_for_update_all_mirrors_worker,
                  data_consistency: :sticky

  describe '#perform' do
    it 'does nothing if the database is read-only' do
      allow(Gitlab::Database).to receive(:read_only?).and_return(true)
      expect(worker).not_to receive(:schedule_mirrors!)

      worker.perform
    end

    it 'does not execute if cannot get the lease' do
      stub_exclusive_lease_taken

      expect(worker).not_to receive(:schedule_mirrors!)

      worker.perform
    end

    it 'removes metadata except correlation_id from the application context before scheduling mirrors' do
      inner_context = nil
      outer_context = nil

      Gitlab::ApplicationContext.with_context(project: build(:project)) do
        outer_context = Gitlab::ApplicationContext.current

        expect(worker).to receive(:schedule_mirrors!) do
          inner_context = Gitlab::ApplicationContext.current

          # `schedule_mirrors!` needs to return an integer.
          0
        end
      end

      worker.perform

      expect(inner_context).to eq(outer_context.slice('correlation_id'))
    end

    it 'schedules mirrors' do
      expect(worker).to receive(:schedule_mirrors!).and_call_original

      worker.perform
    end

    context 'when updates were scheduled' do
      before do
        allow(worker).to receive(:schedule_mirrors!).and_return(1)
      end

      it 'sleeps a bit after scheduling mirrors' do
        expect(Kernel).to receive(:sleep).with(described_class::RESCHEDULE_WAIT)

        worker.perform
      end

      context 'if capacity is available' do
        before do
          allow(Gitlab::Mirror).to receive(:reschedule_immediately?).and_return(true)
        end

        it 'reschedules the job' do
          expect(described_class).to receive(:perform_async)

          worker.perform
        end
      end

      context 'if no capacity is available' do
        before do
          allow(Gitlab::Mirror).to receive(:reschedule_immediately?).and_return(false)
        end

        it 'does not reschedule the job' do
          expect(described_class).not_to receive(:perform_async)

          worker.perform
        end
      end
    end

    context 'when no updates were scheduled' do
      before do
        allow(worker).to receive(:schedule_mirrors!).and_return(0)
        allow(Gitlab::Mirror).to receive(:reschedule_immediately?).and_return(false)
      end

      it 'does not reschedule the job' do
        expect(described_class).not_to receive(:perform_async)

        worker.perform
      end
    end
  end

  describe '#schedule_mirrors!' do
    def schedule_mirrors!(capacity:)
      allow(Gitlab::Mirror).to receive_messages(available_capacity: capacity)

      allow(RepositoryImportWorker).to receive(:perform_async)

      Sidekiq::Testing.inline! do
        worker.schedule_mirrors!
      end
    end

    def expect_import_status(project, status)
      expect(project.import_state.reload.status).to eq(status)
    end

    def expect_import_scheduled(*projects)
      projects.each { |project| expect_import_status(project, 'scheduled') }
    end

    def expect_import_not_scheduled(*projects)
      projects.each { |project| expect_import_status(project, 'none') }
    end

    context 'when the instance is unlicensed' do
      it 'does not schedule when project does not have repository mirrors available' do
        project = create(:project, :mirror)

        stub_licensed_features(repository_mirrors: false)

        schedule_mirrors!(capacity: 5)

        expect_import_not_scheduled(project)
      end
    end

    context 'when the instance is licensed' do
      def scheduled_mirror(at:)
        project = create(:project, :mirror)
        project.import_state.update_column(:next_execution_timestamp, at)
        project
      end

      let_it_be(:project1) { scheduled_mirror(at: 8.weeks.ago) }
      let_it_be(:project2) { scheduled_mirror(at: 7.weeks.ago) }

      context 'when capacity is in excess' do
        it 'schedules all available mirrors' do
          schedule_mirrors!(capacity: 3)

          expect_import_scheduled(project1, project2)
        end
      end
    end

    context 'when the instance checks namespace plans' do
      def scheduled_mirror(at:, licensed:, public: false, subgroup: nil)
        group_args = [:group, :public, subgroup && :nested].compact
        namespace = create(*group_args) # rubocop:disable Rails/SaveBang
        project = create(:project, :public, :mirror, namespace: namespace)

        create(:gitlab_subscription, (licensed ? :bronze : :free), namespace: namespace.root_ancestor)

        project.import_state.update_column(:next_execution_timestamp, at)
        project.update_column(:visibility_level, Gitlab::VisibilityLevel::PRIVATE) unless public
        project
      end

      before do
        stub_application_setting(check_namespace_plan: true)
      end

      let_it_be(:unlicensed_project1) { scheduled_mirror(at: 8.weeks.ago, licensed: false) }
      let_it_be(:unlicensed_project2) { scheduled_mirror(at: 7.weeks.ago, licensed: false) }
      let_it_be(:licensed_project1)   { scheduled_mirror(at: 6.weeks.ago, licensed: true, subgroup: true) }
      let_it_be(:unlicensed_project3) { scheduled_mirror(at: 5.weeks.ago, licensed: false) }
      let_it_be(:licensed_project2)   { scheduled_mirror(at: 4.weeks.ago, licensed: true) }
      let_it_be(:unlicensed_project4) { scheduled_mirror(at: 3.weeks.ago, licensed: false) }
      let_it_be(:public_project)      { scheduled_mirror(at: 1.week.ago, licensed: false, public: true) }

      let(:unlicensed_projects) { [unlicensed_project1, unlicensed_project2, unlicensed_project3, unlicensed_project4] }

      context 'when using SQL to filter projects' do
        before do
          allow(subject).to receive(:check_mirror_plans_in_query?).and_return(true)
        end

        context 'when capacity is in excess' do
          it 'schedules all available mirrors' do
            schedule_mirrors!(capacity: 4)

            expect_import_scheduled(licensed_project1, licensed_project2, public_project)
            expect_import_not_scheduled(*unlicensed_projects)
          end
        end

        context 'when capacity is exactly sufficient' do
          it 'does not include unlicensed non-public projects in batches' do
            # We expect that all three eligible projects will be
            # included in the first batch because the query will only
            # return eligible projects.
            expect(subject).to receive(:pull_mirrors_batch).with(hash_including(batch_size: 6)).and_call_original.once

            schedule_mirrors!(capacity: 3)
          end
        end
      end

      context 'when checking licenses on each record individually' do
        before do
          allow(subject).to receive(:check_mirror_plans_in_query?).and_return(false)
        end

        context 'when capacity is in excess' do
          it "schedules all available mirrors" do
            schedule_mirrors!(capacity: 4)

            expect_import_scheduled(licensed_project1, licensed_project2, public_project)
            expect_import_not_scheduled(*unlicensed_projects)
          end

          it 'requests as many batches as necessary' do
            # The first batch will only contain 3 licensed mirrors, but since we have
            # fewer than 8 mirrors in total, there's no need to request another batch
            expect(subject).to receive(:pull_mirrors_batch).with(hash_including(batch_size: 8)).and_call_original

            schedule_mirrors!(capacity: 4)
          end

          it "does not schedule a mirror of an archived project" do
            licensed_project1.update_column(:archived, true)

            schedule_mirrors!(capacity: 4)

            expect_import_scheduled(licensed_project2, public_project)
            expect_import_not_scheduled(licensed_project1)
            expect_import_not_scheduled(*unlicensed_projects)
          end

          it "does not schedule a mirror of an pending_delete project" do
            licensed_project1.update_column(:pending_delete, true)

            schedule_mirrors!(capacity: 4)

            expect_import_scheduled(licensed_project2, public_project)
            expect_import_not_scheduled(licensed_project1)
            expect_import_not_scheduled(*unlicensed_projects)
          end
        end

        context 'when capacity is exactly sufficient' do
          it "schedules all available mirrors" do
            schedule_mirrors!(capacity: 3)

            expect_import_scheduled(licensed_project1, licensed_project2, public_project)
            expect_import_not_scheduled(*unlicensed_projects)
          end

          it 'requests as many batches as necessary' do
            # The first batch will only contain 2 licensed mirrors, so we need to request another batch
            expect(subject).to receive(:pull_mirrors_batch).with(hash_including(batch_size: 6)).ordered.and_call_original
            expect(subject).to receive(:pull_mirrors_batch).with(hash_including(batch_size: 2)).ordered.and_call_original

            schedule_mirrors!(capacity: 3)
          end
        end

        context 'when capacity is insufficient' do
          it 'schedules mirrors by next_execution_timestamp' do
            schedule_mirrors!(capacity: 2)

            expect_import_scheduled(licensed_project1, licensed_project2)
            expect_import_not_scheduled(*unlicensed_projects, public_project)
          end

          it 'requests as many batches as necessary' do
            # The first batch will only contain 1 licensed mirror, so we need to request another batch
            expect(subject).to receive(:pull_mirrors_batch).with(hash_including(batch_size: 4)).ordered.and_call_original
            expect(subject).to receive(:pull_mirrors_batch).with(hash_including(batch_size: 2)).ordered.and_call_original

            schedule_mirrors!(capacity: 2)
          end
        end

        context 'when capacity is insufficient and the first batch is empty' do
          it 'schedules mirrors by next_execution_timestamp' do
            schedule_mirrors!(capacity: 1)

            expect_import_scheduled(licensed_project1)
            expect_import_not_scheduled(*unlicensed_projects, licensed_project2, public_project)
          end

          it 'requests as many batches as necessary' do
            # The first batch will not contain any licensed mirrors, so we need to request another batch
            expect(subject).to receive(:pull_mirrors_batch).with(hash_including(batch_size: 2)).ordered.and_call_original
            expect(subject).to receive(:pull_mirrors_batch).with(hash_including(batch_size: 2)).ordered.and_call_original

            schedule_mirrors!(capacity: 1)
          end
        end
      end
    end
  end
end
