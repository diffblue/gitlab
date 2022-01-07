# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'gitlab:elastic namespace rake tasks', :elastic, :silence_stdout do
  before do
    Rake.application.rake_require 'tasks/gitlab/elastic'
  end

  describe 'when enabling and disabling elastic settings' do
    let(:settings) { ::Gitlab::CurrentSettings }

    before do
      settings.update!(elasticsearch_search: es_enabled)
    end

    describe 'when enabling elasticsearch with setting initially off' do
      subject { run_rake_task('gitlab:elastic:enable_search_with_elasticsearch') }

      let(:es_enabled) { false }

      it 'enables elasticsearch' do
        expect { subject }.to change { settings.elasticsearch_search }.from(false).to(true)
      end
    end

    describe 'when enabling elasticsearch with setting initially on' do
      subject { run_rake_task('gitlab:elastic:enable_search_with_elasticsearch') }

      let(:es_enabled) { true }

      it 'does nothing when elasticsearch is already enabled' do
        expect { subject }.not_to change { settings.elasticsearch_search }
      end
    end

    describe 'when disabling elasticsearch with setting initially on' do
      subject { run_rake_task('gitlab:elastic:disable_search_with_elasticsearch') }

      let(:es_enabled) { true }

      it 'disables elasticsearch' do
        expect { subject }.to change { settings.elasticsearch_search }.from(true).to(false)
      end
    end

    describe 'when disabling elasticsearch with setting initially off' do
      subject { run_rake_task('gitlab:elastic:disable_search_with_elasticsearch') }

      let(:es_enabled) { false }

      it 'does nothing when elasticsearch is already disabled' do
        expect { subject }.not_to change { settings.elasticsearch_search }
      end
    end
  end

  describe 'create_empty_index' do
    subject { run_rake_task('gitlab:elastic:create_empty_index') }

    before do
      es_helper.delete_index
      es_helper.delete_standalone_indices
      es_helper.delete_migrations_index
    end

    it 'creates the default index' do
      expect { subject }.to change { es_helper.index_exists? }.from(false).to(true)
    end

    context 'when SKIP_ALIAS environment variable is set' do
      before do
        stub_env('SKIP_ALIAS', '1')
      end

      after do
        es_helper.client.indices.delete(index: "#{es_helper.target_name}*")
      end

      it 'does not alias the new index' do
        expect { subject }.not_to change { es_helper.alias_exists?(name: es_helper.target_name) }
      end

      it 'does not create the migrations index if it does not exist' do
        migration_index_name = es_helper.migrations_index_name
        es_helper.delete_index(index_name: migration_index_name)

        expect { subject }.not_to change { es_helper.index_exists?(index_name: migration_index_name) }
      end

      Gitlab::Elastic::Helper::ES_SEPARATE_CLASSES.each do |class_name|
        describe "#{class_name}" do
          it "does not create a standalone index" do
            proxy = ::Elastic::Latest::ApplicationClassProxy.new(class_name, use_separate_indices: true)

            expect { subject }.not_to change { es_helper.alias_exists?(name: proxy.index_name) }
          end
        end
      end
    end

    it 'creates the migrations index if it does not exist' do
      migration_index_name = es_helper.migrations_index_name
      es_helper.delete_index(index_name: migration_index_name)

      expect { subject }.to change { es_helper.index_exists?(index_name: migration_index_name) }.from(false).to(true)
    end

    Gitlab::Elastic::Helper::ES_SEPARATE_CLASSES.each do |class_name|
      describe "#{class_name}" do
        it "creates a standalone index" do
          proxy = ::Elastic::Latest::ApplicationClassProxy.new(class_name, use_separate_indices: true)
          expect { subject }.to change { es_helper.index_exists?(index_name: proxy.index_name) }.from(false).to(true)
        end
      end
    end

    it 'marks all migrations as completed' do
      expect(Elastic::DataMigrationService).to receive(:mark_all_as_completed!).and_call_original

      subject
      refresh_index!

      migrations = Elastic::DataMigrationService.migrations.map(&:version)
      expect(Elastic::MigrationRecord.load_versions(completed: true)).to eq(migrations)
    end
  end

  describe 'delete_index' do
    subject { run_rake_task('gitlab:elastic:delete_index') }

    it 'removes the index' do
      expect { subject }.to change { es_helper.index_exists? }.from(true).to(false)
    end

    it_behaves_like 'deletes all standalone indices' do
      let(:helper) { es_helper }
    end

    it 'removes the migrations index' do
      expect { subject }.to change { es_helper.migrations_index_exists? }.from(true).to(false)
    end

    context 'when the index does not exist' do
      it 'does not error' do
        run_rake_task('gitlab:elastic:delete_index')
        run_rake_task('gitlab:elastic:delete_index')
      end
    end
  end

  context "with elasticsearch_indexing enabled" do
    before do
      stub_ee_application_setting(elasticsearch_indexing: true)
    end

    describe 'index' do
      it 'calls all indexing tasks in order' do
        expect(Rake::Task['gitlab:elastic:recreate_index']).to receive(:invoke).ordered
        expect(Rake::Task['gitlab:elastic:clear_index_status']).to receive(:invoke).ordered
        expect(Rake::Task['gitlab:elastic:index_projects']).to receive(:invoke).ordered
        expect(Rake::Task['gitlab:elastic:index_snippets']).to receive(:invoke).ordered

        run_rake_task 'gitlab:elastic:index'
      end
    end

    describe 'index_projects' do
      let(:project1) { create :project }
      let(:project2) { create :project }
      let(:project3) { create :project }

      before do
        Sidekiq::Testing.disable! do
          project1
          project2
        end
      end

      it 'queues jobs for each project batch' do
        expect(Elastic::ProcessInitialBookkeepingService).to receive(:backfill_projects!).with(project1, project2)

        run_rake_task 'gitlab:elastic:index_projects'
      end

      context 'with limited indexing enabled' do
        before do
          Sidekiq::Testing.disable! do
            project1
            project2
            project3

            create :elasticsearch_indexed_project, project: project1
            create :elasticsearch_indexed_namespace, namespace: project3.namespace
          end

          stub_ee_application_setting(elasticsearch_limit_indexing: true)
        end

        it 'does not queue jobs for projects that should not be indexed' do
          expect(Elastic::ProcessInitialBookkeepingService).to receive(:backfill_projects!).with(project1, project3)

          run_rake_task 'gitlab:elastic:index_projects'
        end
      end
    end

    describe 'index_snippets' do
      it 'indexes snippets' do
        expect(Snippet).to receive(:es_import)

        run_rake_task 'gitlab:elastic:index_snippets'
      end
    end

    describe 'recreate_index' do
      it 'calls all related subtasks in order' do
        expect(Rake::Task['gitlab:elastic:delete_index']).to receive(:invoke).ordered
        expect(Rake::Task['gitlab:elastic:create_empty_index']).to receive(:invoke).ordered

        run_rake_task 'gitlab:elastic:recreate_index'
      end
    end
  end

  context "with elasticsearch_indexing is disabled" do
    it 'enables `elasticsearch_indexing`' do
      expect { run_rake_task 'gitlab:elastic:index' }.to change {
        Gitlab::CurrentSettings.elasticsearch_indexing?
      }.from(false).to(true)
    end
  end

  describe 'mark_reindex_failed' do
    subject { run_rake_task('gitlab:elastic:mark_reindex_failed') }

    context 'when there is a running reindex job' do
      before do
        Elastic::ReindexingTask.create!
      end

      it 'marks the current reindex job as failed' do
        expect { subject }.to change {Elastic::ReindexingTask.running?}.from(true).to(false)
      end

      it 'prints a message after marking it as failed' do
        expect { subject }.to output("Marked the current reindexing job as failed.\n").to_stdout
      end
    end

    context 'when no running reindex job' do
      it 'just prints a message' do
        expect { subject }.to output("Did not find the current running reindexing job.\n").to_stdout
      end
    end
  end

  describe 'list_pending_migrations' do
    subject { run_rake_task('gitlab:elastic:list_pending_migrations') }

    context 'when there are pending migrations' do
      let(:pending_migration1) { ::Elastic::DataMigrationService.migrations[1] }
      let(:pending_migration2) { ::Elastic::DataMigrationService.migrations[2] }

      before do
        pending_migration1.save!(completed: false)
        pending_migration2.save!(completed: false)
      end

      it 'outputs pending migrations' do
        expect { subject }.to output(/#{pending_migration1.name}\n#{pending_migration2.name}/).to_stdout
      end
    end

    context 'when there is no pending migrations' do
      it 'outputs message there are no pending migrations' do
        expect { subject }.to output(/There are no pending migrations./).to_stdout
      end
    end
  end

  describe 'estimate_cluster_size' do
    subject { run_rake_task('gitlab:elastic:estimate_cluster_size') }

    before do
      create(:namespace_root_storage_statistics, repository_size: 1.megabyte)
      create(:namespace_root_storage_statistics, repository_size: 10.megabyte)
      create(:namespace_root_storage_statistics, repository_size: 30.megabyte)
    end

    it 'outputs estimates' do
      expect { subject }.to output(/your cluster size should be at least 20.5 MB/).to_stdout
    end
  end

  describe 'pause_indexing' do
    subject { run_rake_task('gitlab:elastic:pause_indexing') }

    let(:settings) { ::Gitlab::CurrentSettings }

    before do
      allow(settings).to receive(:elasticsearch_pause_indexing?).and_return(indexing_paused)
    end

    context 'when indexing is already paused' do
      let(:indexing_paused) { true }

      it 'does not do anything' do
        expect(settings).not_to receive(:update!)
        expect { subject }.to output(/Indexing is already paused/).to_stdout
      end
    end

    context 'when indexing is running' do
      let(:indexing_paused) { false }

      it 'pauses indexing' do
        expect(settings).to receive(:update!).with(elasticsearch_pause_indexing: true)
        expect { subject }.to output(/Indexing is now paused/).to_stdout
      end
    end

    describe 'resume_indexing' do
      subject { run_rake_task('gitlab:elastic:resume_indexing') }

      let(:settings) { ::Gitlab::CurrentSettings }

      before do
        allow(settings).to receive(:elasticsearch_pause_indexing?).and_return(indexing_paused)
      end

      context 'when indexing is already running' do
        let(:indexing_paused) { false }

        it 'does not do anything' do
          expect(settings).not_to receive(:update!)
          expect { subject }.to output(/Indexing is already running/).to_stdout
        end
      end

      context 'when indexing is not running' do
        let(:indexing_paused) { true }

        it 'resumes indexing' do
          expect(settings).to receive(:update!).with(elasticsearch_pause_indexing: false)
          expect { subject }.to output(/Indexing is now running/).to_stdout
        end
      end
    end
  end
end
