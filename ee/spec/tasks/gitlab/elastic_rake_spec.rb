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
    before do
      stub_ee_application_setting(elasticsearch_indexing: true)
    end

    describe 'index' do
      subject { run_rake_task('gitlab:elastic:index') }

      context 'when on GitLab.com', :saas do
        it 'raises an error' do
          expect { subject }.to raise_error('This task cannot be run on GitLab.com')
        end
      end

      it 'calls all indexing tasks in order' do
        expect(Rake::Task['gitlab:elastic:recreate_index']).to receive(:invoke).ordered
        expect(Rake::Task['gitlab:elastic:clear_index_status']).to receive(:invoke).ordered
        expect(Rake::Task['gitlab:elastic:index_group_entities']).to receive(:invoke).ordered
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

    describe 'index_group_entities' do
      subject { run_rake_task('gitlab:elastic:index_group_entities') }

      context 'when on GitLab.com', :saas do
        it 'raises an error' do
          expect { subject }.to raise_error('This task cannot be run on GitLab.com')
        end
      end

      it 'calls all indexing tasks in order for the group entities' do
        expect(Rake::Task['gitlab:elastic:index_epics']).to receive(:invoke).ordered
        expect(Rake::Task['gitlab:elastic:index_group_wikis']).to receive(:invoke).ordered

        subject
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

    describe 'index_epics' do
      let_it_be(:epic) { create(:epic) }

      context 'when on GitLab.com', :saas do
        it 'raises an error' do
          expect { run_rake_task 'gitlab:elastic:index_epics' }.to raise_error('This task cannot be run on GitLab.com')
        end
      end

      it 'calls maintain_indexed_group_associations for groups' do
        expect(Elastic::ProcessInitialBookkeepingService).to receive(:maintain_indexed_group_associations!)
          .with(epic.group)

        run_rake_task 'gitlab:elastic:index_epics'
      end

      context 'with limited indexing enabled' do
        let_it_be(:group1) { create(:group) }
        let_it_be(:group2) { create(:group) }
        let_it_be(:group3) { create(:group) }

        before do
          create(:elasticsearch_indexed_namespace, namespace: group1)
          create(:elasticsearch_indexed_namespace, namespace: group3)

          stub_ee_application_setting(elasticsearch_limit_indexing: true)
        end

        it 'does not call maintain_indexed_group_associations for groups that should not be indexed' do
          expect(Elastic::ProcessBookkeepingService).to receive(:maintain_indexed_group_associations!)
            .with(group1, group3)

          run_rake_task 'gitlab:elastic:index_epics'
        end
      end
    end

    describe 'index_group_wikis' do
      let(:group1) { create(:group) }
      let(:group2) { create(:group) }
      let(:group3) { create(:group) }
      let(:subgrp) { create(:group, parent: group1) }
      let(:wiki1) { create(:group_wiki, group: group1) }
      let(:wiki2) { create(:group_wiki, group: group2) }
      let(:wiki3) { create(:group_wiki, group: group3) }
      let(:wiki4) { create(:group_wiki, group: subgrp) }

      context 'when on GitLab.com', :saas do
        it 'raises an error' do
          expect { run_rake_task('gitlab:elastic:index') }.to raise_error('This task cannot be run on GitLab.com')
        end
      end

      context 'with limited indexing disabled' do
        before do
          [wiki1, wiki2, wiki3, wiki4].each do |w|
            w.create_page('index_page', 'Bla bla term')
            w.index_wiki_blobs
          end
        end

        it 'calls ElasticWikiIndexerWorker for groups' do
          expect(ElasticWikiIndexerWorker).to receive(:perform_async).with(group1.id, group1.class.name, force: true)
          expect(ElasticWikiIndexerWorker).to receive(:perform_async).with(group2.id, group2.class.name, force: true)
          expect(ElasticWikiIndexerWorker).to receive(:perform_async).with(group3.id, group3.class.name, force: true)
          expect(ElasticWikiIndexerWorker).to receive(:perform_async).with(subgrp.id, subgrp.class.name, force: true)
          run_rake_task 'gitlab:elastic:index_group_wikis'
        end
      end

      context 'with limited indexing enabled' do
        before do
          create(:elasticsearch_indexed_namespace, namespace: group1)
          create(:elasticsearch_indexed_namespace, namespace: group3)

          stub_ee_application_setting(elasticsearch_limit_indexing: true)

          [wiki1, wiki2, wiki3, wiki4].each do |w|
            w.create_page('index_page', 'Bla bla term')
            w.index_wiki_blobs
          end
        end

        it 'calls ElasticWikiIndexerWorker for groups which has elasticsearch enabled' do
          expect(ElasticWikiIndexerWorker).to receive(:perform_async).with(group1.id, group1.class.name, force: true)
          expect(ElasticWikiIndexerWorker).to receive(:perform_async).with(group3.id, group3.class.name, force: true)
          expect(ElasticWikiIndexerWorker).to receive(:perform_async).with(subgrp.id, subgrp.class.name, force: true)
          expect(ElasticWikiIndexerWorker).not_to receive(:perform_async).with group2.id, group2.class.name, force: true
          run_rake_task 'gitlab:elastic:index_group_wikis'
        end
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
      let(:two_most_recent_migrations) { ::Elastic::DataMigrationService.migrations.last(2) }
      let(:pending_migration1) { two_most_recent_migrations.first }
      let(:pending_migration2) { two_most_recent_migrations.second }

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

    context 'when pending migrations are obsolete' do
      let(:obsolete_pending_migration) { ::Elastic::DataMigrationService.migrations.first }

      before do
        obsolete_pending_migration.save!(completed: false)
      end

      it 'outputs that the pending migration is obsolete' do
        expect { subject }.to output(/#{obsolete_pending_migration.name} \[Obsolete\]/).to_stdout
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
      expect { subject }.to output(/your cluster size should be at least 20.5 MiB/).to_stdout
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
    let_it_be(:project_no_repository) { create(:project) }
    let_it_be(:project_empty_repository) { create(:project, :empty_repo) }

    context 'when on GitLab.com', :saas do
      it 'raises an error' do
        expect { subject }.to raise_error('This task cannot be run on GitLab.com')
      end
    end

    context 'when projects missing from index' do
      it 'displays non-indexed projects' do
        expected = <<~STD_OUT
          Project '#{project.full_path}' (ID: #{project.id}) isn't indexed.
          Project '#{project_no_repository.full_path}' (ID: #{project_no_repository.id}) isn't indexed.
          Project '#{project_empty_repository.full_path}' (ID: #{project_empty_repository.id}) isn't indexed.
          3 out of 3 non-indexed projects shown.
        STD_OUT

        expect { subject }.to output(expected).to_stdout
      end

      context 'when elasticsearch_limit_indexing? is enabled' do
        before do
          stub_ee_application_setting(elasticsearch_limit_indexing: true)
        end

        it 'only displays non-indexed projects that are setup for indexing' do
          create(:elasticsearch_indexed_project, project: project_no_repository)

          expected = <<~STD_OUT
            Project '#{project_no_repository.full_path}' (ID: #{project_no_repository.id}) isn't indexed.
            1 out of 1 non-indexed projects shown.
          STD_OUT

          expect { subject }.to output(expected).to_stdout
        end
      end
    end

    context 'when all projects are indexed' do
      before do
        create(:index_status, project: project)
        create(:index_status, project: project_no_repository)
        create(:index_status, project: project_empty_repository)
      end

      it 'displays that all projects are indexed' do
        expect { subject }.to output(/All projects are currently indexed/).to_stdout
      end
    end
  end

  describe 'index_projects_status' do
    subject { run_rake_task('gitlab:elastic:index_projects_status') }

    let_it_be_with_reload(:project) { create(:project, :repository) }
    let_it_be_with_reload(:project_no_repository) { create(:project) }
    let_it_be_with_reload(:project_empty_repository) { create(:project, :empty_repo) }

    context 'when on GitLab.com', :saas do
      it 'raises an error' do
        expect { subject }.to raise_error('This task cannot be run on GitLab.com')
      end
    end

    context 'when some projects missing from index' do
      before do
        create(:index_status, project: project)
      end

      it 'displays completion percentage' do
        expected = <<~STD_OUT
          Indexing is 33.33% complete (1/3 projects)
        STD_OUT

        expect { subject }.to output(expected).to_stdout
      end

      context 'when elasticsearch_limit_indexing? is enabled' do
        before do
          stub_ee_application_setting(elasticsearch_limit_indexing: true)
        end

        it 'only displays non-indexed projects that are setup for indexing' do
          create(:elasticsearch_indexed_project, project: project_no_repository)

          expected = <<~STD_OUT
            Indexing is 0.00% complete (0/1 projects)
          STD_OUT

          expect { subject }.to output(expected).to_stdout
        end
      end
    end

    context 'when all projects are indexed' do
      before do
        create(:index_status, project: project)
        create(:index_status, project: project_no_repository)
        create(:index_status, project: project_empty_repository)
      end

      it 'displays that all projects are indexed' do
        expected = <<~STD_OUT
          Indexing is 100.00% complete (3/3 projects)
        STD_OUT

        expect { subject }.to output(expected).to_stdout
      end

      context 'when elasticsearch_limit_indexing? is enabled' do
        before do
          stub_ee_application_setting(elasticsearch_limit_indexing: true)
        end

        it 'only displays non-indexed projects that are setup for indexing' do
          create(:elasticsearch_indexed_project, project: project_empty_repository)

          expected = <<~STD_OUT
            Indexing is 100.00% complete (1/1 projects)
          STD_OUT

          expect { subject }.to output(expected).to_stdout
        end
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
        'Requeue Indexing workers:\\s+no\\s+',
        'Pause indexing:\\s+no\\s+',
        'Indexing restrictions enabled:\\s+no\\s+'
      ].join(''))
      expect { subject }.to output(expected_regex).to_stdout
    end

    it 'outputs file size limit' do
      expect { subject }.to output(/File size limit:\s+\d+ KiB/).to_stdout
    end

    it 'outputs indexing number of shards' do
      expect { subject }.to output(/Indexing number of shards:\s+\d+/).to_stdout
    end

    it 'outputs queue sizes' do
      allow(Elastic::ProcessInitialBookkeepingService).to receive(:queue_size).and_return(100)
      allow(Elastic::ProcessBookkeepingService).to receive(:queue_size).and_return(200)

      expect { subject }.to output(/Initial queue:\s+100\s+Incremental queue:\s+200/).to_stdout
    end

    it 'outputs pending migrations' do
      pending_migration = ::Elastic::DataMigrationService.migrations.last
      obsolete_migration = ::Elastic::DataMigrationService.migrations.first
      pending_migration.save!(completed: false)
      obsolete_migration.save!(completed: false)

      allow(::Elastic::DataMigrationService).to receive(:pending_migrations)
        .and_return([pending_migration, obsolete_migration])

      expect { subject }.to output(
        /Pending Migrations\s+#{pending_migration.name}\s+#{obsolete_migration.name} \[Obsolete\]/
      ).to_stdout
    end

    it 'outputs current migration' do
      migration = ::Elastic::DataMigrationService.migrations.last
      allow(migration).to receive(:started?).and_return(true)
      allow(migration).to receive(:load_state).and_return({ test: 'value' })
      allow(Elastic::MigrationRecord).to receive(:current_migration).and_return(migration)

      expected_regex = Regexp.new([
        "Name:\\s+#{migration.name}\\s+",
        'Started:\\s+yes\\s+',
        'Halted:\\s+no\\s+',
        'Failed:\\s+no\\s+',
        'Obsolete:\\s+no\\s+',
        'Current state:\\s+{"test":"value"}'
      ].join(''))

      expect { subject }.to output(expected_regex).to_stdout
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

  describe 'clear_index_status' do
    subject { run_rake_task('gitlab:elastic:clear_index_status') }

    it 'deletes all records for Elastic::GroupIndexStatus and IndexStatus tables' do
      expect(Elastic::GroupIndexStatus).to receive(:delete_all)
      expect(IndexStatus).to receive(:delete_all)

      expected = <<~STD_OUT
        Index status has been reset
      STD_OUT

      expect { subject }.to output(expected).to_stdout
    end
  end
end
