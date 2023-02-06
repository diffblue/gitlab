# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'gitlab:elastic namespace rake tasks', :elastic_clean, :silence_stdout,
feature_category: :global_search do
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
        es_helper.client.cat.indices(index: "#{es_helper.target_name}-*", h: 'index').split("\n").each do |index_name|
          es_helper.client.indices.delete(index: index_name)
        end
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
        describe class_name do
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
      describe class_name do
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
    subject { run_rake_task('gitlab:elastic:index') }

    before do
      stub_ee_application_setting(elasticsearch_indexing: true)
    end

    describe 'index' do
      it 'calls all indexing tasks in order' do
        expect(Rake::Task['gitlab:elastic:recreate_index']).to receive(:invoke).ordered
        expect(Rake::Task['gitlab:elastic:clear_index_status']).to receive(:invoke).ordered
        expect(Rake::Task['gitlab:elastic:index_projects']).to receive(:invoke).ordered
        expect(Rake::Task['gitlab:elastic:index_snippets']).to receive(:invoke).ordered
        expect(Rake::Task['gitlab:elastic:index_users']).to receive(:invoke).ordered

        subject
      end

      it 'outputs warning if indexing is paused' do
        stub_ee_application_setting(elasticsearch_pause_indexing: true)

        expect { subject }.to output(/WARNING: `elasticsearch_pause_indexing` is enabled/).to_stdout
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

    describe 'index_users' do
      let_it_be(:users) { create_list(:user, 2) }

      it 'queues jobs for all users' do
        expect(Elastic::ProcessInitialBookkeepingService).to receive(:track!).with(*users).once

        run_rake_task 'gitlab:elastic:index_users'
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
        expect { subject }.to change { Elastic::ReindexingTask.running? }.from(true).to(false)
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

  describe 'projects_not_indexed' do
    subject { run_rake_task('gitlab:elastic:projects_not_indexed') }

    let_it_be(:project) { create(:project, :repository) }

    context 'no projects are indexed' do
      it 'displays non-indexed projects' do
        expected = <<~END
          Project '#{project.full_path}' (ID: #{project.id}) isn't indexed.
          1 out of 1 non-indexed projects shown.
        END

        expect { subject }.to output(expected).to_stdout
      end
    end

    context 'all projects are indexed' do
      before do
        IndexStatus.create!(project: project, indexed_at: Time.current, last_commit: 'foo')
      end

      it 'displays that all projects are indexed' do
        expect { subject }.to output(/All projects are currently indexed/).to_stdout
      end

      it 'does not include projects without repositories' do
        create(:project)

        expect { subject }.to output(/All projects are currently indexed/).to_stdout
      end
    end
  end

  describe 'info' do
    subject { run_rake_task('gitlab:elastic:info') }

    let(:settings) { ::Gitlab::CurrentSettings }

    before do
      settings.update!(elasticsearch_search: true, elasticsearch_indexing: true)
    end

    it 'outputs server version' do
      expect { subject }.to output(/Server version:\s+\d+.\d+.\d+/).to_stdout
    end

    it 'outputs server distribution' do
      expect { subject }.to output(/Server distribution:\s+\w+/).to_stdout
    end

    it 'outputs indexing and search settings' do
      expected_regex = Regexp.new([
        'Indexing enabled:\\s+yes\\s+',
        'Search enabled:\\s+yes\\s+',
        'Pause indexing:\\s+no\\s+',
        'Indexing restrictions enabled:\\s+no\\s+'
      ].join(''))
      expect { subject }.to output(expected_regex).to_stdout
    end

    it 'outputs file size limit' do
      expect { subject }.to output(/File size limit:\s+\d+ KiB/).to_stdout
    end

    it 'outputs queue sizes' do
      allow(Elastic::ProcessInitialBookkeepingService).to receive(:queue_size).and_return(100)
      allow(Elastic::ProcessBookkeepingService).to receive(:queue_size).and_return(200)

      expect { subject }.to output(/Initial queue:\s+100\s+Incremental queue:\s+200/).to_stdout
    end

    it 'outputs pending migrations' do
      migration = instance_double(
        Elastic::MigrationRecord,
        name: 'TestMigration',
        started?: true,
        halted?: false,
        failed?: false,
        load_state: { test: 'value' }
      )

      allow(::Elastic::DataMigrationService).to receive(:pending_migrations).and_return([migration])

      expect { subject }.to output(
        /Pending Migrations\s+#{migration.name}/
      ).to_stdout
    end

    it 'outputs current migration' do
      migration = instance_double(
        Elastic::MigrationRecord,
        name: 'TestMigration',
        started?: true,
        halted?: false,
        failed?: false,
        load_state: { test: 'value' }
      )
      allow(Elastic::MigrationRecord).to receive(:current_migration).and_return(migration)

      expect { subject }.to output(
        /Name:\s+TestMigration\s+Started:\s+yes\s+Halted:\s+no\s+Failed:\s+no\s+Current state:\s+{"test":"value"}/
      ).to_stdout
    end

    context 'with index settings' do
      let(:setting) do
        Elastic::IndexSetting.new(number_of_replicas: 1, number_of_shards: 8, alias_name: 'gitlab-development')
      end

      before do
        allow(Elastic::IndexSetting).to receive(:order).and_return([setting])
      end

      it 'outputs failed index setting' do
        allow(es_helper.client).to receive(:indices).and_raise(Timeout::Error)

        expect { subject }.to output(
          /failed to load indices for gitlab-development/
        ).to_stdout
      end

      it 'outputs index settings' do
        indices = instance_double(Elasticsearch::API::Indices::IndicesClient)
        allow(es_helper.client).to receive(:indices).and_return(indices)
        allow(indices).to receive(:get_settings).with(index: setting.alias_name).and_return({
          setting.alias_name => {
            "settings" => {
              "index" => {
                "number_of_shards" => 5,
                "number_of_replicas" => 1,
                "blocks" => {
                  "write" => 'true'
                }
              }
            }
          }
        })

        expect { subject }.to output(
          /#{setting.alias_name}:\s+number_of_shards: 5\s+number_of_replicas: 1\s+blocks\.write: yes/
        ).to_stdout
      end
    end
  end
end
