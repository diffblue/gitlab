# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'geo rake tasks', :geo, :silence_stdout do
  include ::EE::GeoHelpers

  before do
    Rake.application.rake_require 'active_record/railties/databases'
    Rake.application.rake_require 'tasks/gitlab/db'
    Rake.application.rake_require 'tasks/geo'

    # empty task as env is already loaded
    Rake::Task.define_task :environment

    stub_licensed_features(geo: true)
  end

  it 'Gitlab:Geo::DatabaseTasks responds to all methods used in Geo rake tasks' do
    %i[
      drop_current
      create_current
      migrate
      rollback
      version
      load_schema_current
      load_seed
      dump_schema_after_migration?
      pending_migrations
    ].each do |method|
      expect(Gitlab::Geo::DatabaseTasks).to respond_to(method)
    end
  end

  it 'Gitlab::Geo::GeoTasks responds to all methods used in Geo rake tasks' do
    %i[
      set_primary_geo_node
      update_primary_geo_node_url
    ].each do |method|
      expect(Gitlab::Geo::GeoTasks).to respond_to(method)
    end
  end

  it 'Gitlab::Geo::DatabaseTasks::Migrate responds to all methods used in Geo rake tasks' do
    %i[up down status].each do |method|
      expect(Gitlab::Geo::DatabaseTasks::Migrate).to respond_to(method)
    end
  end

  it 'Gitlab::Geo::DatabaseTasks::Test responds to all methods used in Geo rake tasks' do
    %i[load purge].each do |method|
      expect(Gitlab::Geo::DatabaseTasks::Test).to respond_to(method)
    end
  end

  it 'Gitlab::Geo::DatabaseTasks::Schema responds to .dump method used in Geo rake tasks' do
    expect(Gitlab::Geo::DatabaseTasks::Schema).to respond_to(:dump)
  end

  describe 'geo:db:drop' do
    it 'drops the current database' do
      expect(Gitlab::Geo::DatabaseTasks).to receive(:drop_current)

      run_rake_task('geo:db:drop')
    end
  end

  describe 'geo:db:create' do
    it 'creates a Geo tracking database' do
      expect(Gitlab::Geo::DatabaseTasks).to receive(:create_current)

      run_rake_task('geo:db:create')
    end
  end

  describe 'geo:db:migrate' do
    it 'migrates a Geo tracking database' do
      expect(Gitlab::Geo::DatabaseTasks).to receive(:migrate)
      expect(Rake::Task['geo:db:_dump']).to receive(:invoke)

      run_rake_task('geo:db:migrate')
    end
  end

  describe 'geo:db:rollback' do
    it 'rolls back a Geo tracking database' do
      expect(Gitlab::Geo::DatabaseTasks).to receive(:rollback)
      expect(Rake::Task['geo:db:_dump']).to receive(:invoke)

      run_rake_task('geo:db:rollback')
    end
  end

  describe 'geo:db:version' do
    it 'retrieves current schema version number' do
      expect(Gitlab::Geo::DatabaseTasks).to receive(:version)

      run_rake_task('geo:db:version')
    end
  end

  describe 'geo:db:reset' do
    it 'drops, recreates database, and loads seeds' do
      expect(Rake::Task['geo:db:drop']).to receive(:invoke)
      expect(Rake::Task['geo:db:create']).to receive(:invoke)
      expect(Rake::Task['geo:db:setup']).to receive(:invoke)

      run_rake_task('geo:db:reset')
    end
  end

  describe 'geo:db:seed' do
    it 'loads seed data' do
      allow(Rake::Task['geo:db:abort_if_pending_migrations']).to receive(:invoke).and_return(false)
      expect(Gitlab::Geo::DatabaseTasks).to receive(:load_seed)

      run_rake_task('geo:db:seed')
    end
  end

  describe 'geo:db:_dump' do
    it 'dumps the schema' do
      allow(Gitlab::Geo::DatabaseTasks).to receive(:dump_schema_after_migration?).and_return(true)
      expect(Rake::Task['geo:db:schema:dump']).to receive(:invoke)

      run_rake_task('geo:db:_dump')
    end
  end

  describe 'geo:db:abort_if_pending_migrations' do
    it 'raises an error if there are pending migrations' do
      pending_migration = double('pending migration', version: 12, name: 'Test')
      allow(Gitlab::Geo::DatabaseTasks).to receive(:pending_migrations).and_return([pending_migration])

      expect { run_rake_task('geo:db:abort_if_pending_migrations') }.to raise_error(%{Run `rake geo:db:migrate` to update your database then try again.})
    end
  end

  describe 'geo:db:schema_load' do
    it 'loads schema file into database' do
      allow(ENV).to receive(:[]).with('SCHEMA')
      expect(Gitlab::Geo::DatabaseTasks).to receive(:load_schema_current).with(:sql, ENV['SCHEMA'])

      run_rake_task('geo:db:schema:load')
    end
  end

  describe 'geo:db:schema_dump' do
    it 'creates a clean structure.sql file', :reestablished_active_record_base do
      expect(Gitlab::Geo::DatabaseTasks::Schema).to receive(:dump)
      expect(Rake::Task['gitlab:db:clean_structure_sql']).to receive(:invoke)

      run_rake_task('geo:db:schema:dump')
    end
  end

  describe 'geo:db:migrate:up' do
    it 'runs up method for given migration' do
      expect(Gitlab::Geo::DatabaseTasks::Migrate).to receive(:up)
      expect(Rake::Task['geo:db:_dump']).to receive(:invoke)

      run_rake_task('geo:db:migrate:up')
    end
  end

  describe 'geo:db:migrate:down' do
    it 'runs down method for given migration' do
      expect(Gitlab::Geo::DatabaseTasks::Migrate).to receive(:down)
      expect(Rake::Task['geo:db:_dump']).to receive(:invoke)

      run_rake_task('geo:db:migrate:down')
    end
  end

  describe 'geo:db:migrate:redo' do
    context 'without env var set' do
      it 'does not run migrations' do
        expect(Rake::Task['geo:db:migrate:down']).not_to receive(:invoke)
        expect(Rake::Task['geo:db:rollback']).to receive(:invoke)

        run_rake_task('geo:db:migrate:redo')
      end
    end

    context 'with env var set' do
      it 'does run migrations' do
        allow(ENV).to receive(:[]).with('VERSION').and_return(1)
        expect(Rake::Task['geo:db:migrate:down']).to receive(:invoke)
        expect(Rake::Task['geo:db:rollback']).not_to receive(:invoke)

        run_rake_task('geo:db:migrate:redo')
      end
    end
  end

  describe 'geo:db:migrate:status' do
    it 'displays migration status' do
      expect(Gitlab::Geo::DatabaseTasks::Migrate).to receive(:status)

      run_rake_task('geo:db:migrate:status')
    end
  end

  describe 'geo:db:test:prepare' do
    it 'check for pending migrations and load schema in test environment' do
      expect(Rake::Task['geo:db:test:load']).to receive(:invoke)

      run_rake_task('geo:db:test:prepare')
    end
  end

  describe 'geo:db:test:load' do
    it 'recreates database in test environment' do
      expect(Gitlab::Geo::DatabaseTasks::Test).to receive(:load)
      expect(Gitlab::Geo::DatabaseTasks::Test).to receive(:purge)

      run_rake_task('geo:db:test:load')
    end
  end

  describe 'geo:db:test:purge' do
    it 'empties database in test environment' do
      expect(Gitlab::Geo::DatabaseTasks::Test).to receive(:purge)

      run_rake_task('geo:db:test:purge')
    end
  end

  describe 'geo:set_primary_node' do
    before do
      stub_config_setting(url: 'https://example.com:1234/relative_part')
      stub_geo_setting(node_name: 'Region 1 node')
    end

    it 'creates a GeoNode' do
      expect(GeoNode.count).to eq(0)

      run_rake_task('geo:set_primary_node')

      expect(GeoNode.count).to eq(1)

      node = GeoNode.first

      expect(node.name).to eq('Region 1 node')
      expect(node.uri.scheme).to eq('https')
      expect(node.url).to eq('https://example.com:1234/relative_part/')
      expect(node.primary).to be_truthy
    end
  end

  describe 'geo:set_secondary_as_primary', :use_clean_rails_memory_store_caching do
    let!(:current_node) { create(:geo_node) }
    let!(:primary_node) { create(:geo_node, :primary) }

    before do
      stub_current_geo_node(current_node)

      allow(GeoNode).to receive(:current_node).and_return(current_node)
    end

    it 'removes primary and sets secondary as primary' do
      # Pre-warming the cache. See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/22021
      Gitlab::Geo.primary_node

      run_rake_task('geo:set_secondary_as_primary')

      expect(current_node.primary?).to be_truthy
      expect(GeoNode.count).to eq(1)
    end
  end

  describe 'geo:update_primary_node_url' do
    before do
      allow(GeoNode).to receive(:current_node_url).and_return('https://primary.geo.example.com')
      stub_current_geo_node(primary_node)
    end

    context 'when the machine Geo node name is not explicitly configured' do
      let(:primary_node) { create(:geo_node, :primary, url: 'https://secondary.geo.example.com', name: 'https://secondary.geo.example.com') }

      before do
        # As if Gitlab.config.geo.node_name is defaulting to external_url (this happens in an initializer)
        allow(GeoNode).to receive(:current_node_name).and_return('https://primary.geo.example.com')
      end

      it 'updates Geo primary node URL and name' do
        run_rake_task('geo:update_primary_node_url')

        expect(primary_node.reload.url).to eq 'https://primary.geo.example.com/'
        expect(primary_node.name).to eq 'https://primary.geo.example.com/'
      end
    end

    context 'when the machine Geo node name is explicitly configured' do
      let(:node_name) { 'Brazil DC' }
      let(:primary_node) { create(:geo_node, :primary, url: 'https://secondary.geo.example.com', name: node_name) }

      before do
        allow(GeoNode).to receive(:current_node_name).and_return(node_name)
      end

      it 'updates Geo primary node URL only' do
        run_rake_task('geo:update_primary_node_url')

        expect(primary_node.reload.url).to eq 'https://primary.geo.example.com/'
        expect(primary_node.name).to eq node_name
      end
    end
  end

  describe 'geo:status' do
    context 'when geo is not properly configured' do
      it 'returns misconfigured when not a primary nor a secondary site' do
        expect { run_rake_task('geo:status') }.to raise_error("Gitlab Geo is not configured for this site")
      end
    end

    context 'without a valid license' do
      before do
        stub_licensed_features(geo: false)
      end

      it 'runs with an error' do
        expect { run_rake_task('geo:status') }.to raise_error("GitLab Geo is not supported with this license. Please contact the sales team: https://about.gitlab.com/sales.")
      end
    end

    context 'with a valid license' do
      let!(:current_node) { create(:geo_node) }
      let!(:primary_node) { create(:geo_node, :primary) }
      let!(:geo_event_log) { create(:geo_event_log) }
      let!(:geo_node_status) { build(:geo_node_status, :healthy, geo_node: current_node) }
      let(:checks) do
        [
          /Name: /,
          /URL: /,
          /GitLab Version: /,
          /Geo Role: /,
          /Health Status: /,
          /Sync Settings: /,
          /Database replication lag: /,
          /Repositories: /,
          /Verified Repositories: /,
          /Wikis: /,
          /Verified Wikis: /,
          /Uploads: /,
          /CI job artifacts: /,
          /Container repositories: /,
          /Design repositories: /,
          /Repositories Checked: /,
          /Last event ID seen from primary: /,
          /Last status report was: /
        ] + Gitlab::Geo.verification_enabled_replicator_classes.map { |k| /#{k.replicable_title_plural} Verified:/ } +
          Gitlab::Geo.enabled_replicator_classes.map { |k| /#{k.replicable_title_plural}:/ }
      end

      before do
        stub_licensed_features(geo: true)
        stub_current_geo_node(current_node)

        allow(GeoNodeStatus).to receive(:current_node_status).and_return(geo_node_status)
        allow(Gitlab.config.geo.registry_replication).to receive(:enabled).and_return(true)
      end

      it 'runs with no error' do
        expect { run_rake_task('geo:status') }.not_to raise_error
      end

      context 'with a healthy node' do
        before do
          geo_node_status.status_message = nil
        end

        it 'shows status as healthy' do
          expect { run_rake_task('geo:status') }.to output(/Health Status: Healthy/).to_stdout
        end

        it 'does not show health status summary' do
          expect { run_rake_task('geo:status') }.not_to output(/Health Status Summary/).to_stdout
        end

        context 'with SSF LFS replication eneabled' do
          it 'prints messages for all the checks' do
            checks.each do |text|
              expect { run_rake_task('geo:status') }.to output(text).to_stdout
            end
          end
        end
      end

      context 'with an unhealthy node' do
        before do
          geo_node_status.status_message = 'Something went wrong'
        end

        it 'shows status as unhealthy' do
          expect { run_rake_task('geo:status') }.to output(/Health Status: Unhealthy/).to_stdout
        end

        it 'shows health status summary' do
          expect { run_rake_task('geo:status') }.to output(/Health Status Summary: Something went wrong/).to_stdout
        end
      end
    end
  end

  describe 'geo:site:role' do
    context 'when in a primary site' do
      it 'returns primary' do
        create(:geo_node, :primary, name: 'primary')
        allow(GeoNode).to receive(:current_node_name).and_return('primary')

        expect { run_rake_task('geo:site:role') }.to output(/primary/).to_stdout
      end
    end

    context 'when in a secondary site' do
      it 'returns secondary' do
        create(:geo_node, :secondary, name: 'secondary')
        allow(GeoNode).to receive(:current_node_name).and_return('secondary')

        expect { run_rake_task('geo:site:role') }.to output(/secondary/).to_stdout
      end
    end

    it 'returns misconfigured when not a primary nor a secondary site' do
      expect { run_rake_task('geo:site:role') }.to output(/misconfigured/).to_stdout & raise_error(SystemExit)
    end
  end

  describe 'geo:run_orphaned_project_registry_cleaner' do
    let!(:current_node) { create(:geo_node) }

    before do
      stub_current_geo_node(current_node)

      create(:geo_project_registry)
      create(:geo_project_registry)

      @orphaned = create(:geo_project_registry)
      @orphaned.project.delete
      @orphaned1 = create(:geo_project_registry)
      @orphaned1.project.delete

      create(:geo_project_registry)
    end

    it 'removes orphaned registries' do
      run_rake_task('geo:run_orphaned_project_registry_cleaner')

      expect(Geo::ProjectRegistry.count).to be 3
      expect(Geo::ProjectRegistry.find_by_id(@orphaned.id)).to be nil
    end

    it 'removes orphaned registries taking into account TO_PROJECT_ID' do
      stub_env('FROM_PROJECT_ID' => nil, 'TO_PROJECT_ID' => @orphaned.project_id)

      run_rake_task('geo:run_orphaned_project_registry_cleaner')

      expect(Geo::ProjectRegistry.count).to be 4
      expect(Geo::ProjectRegistry.find_by_id(@orphaned.id)).to be nil
      expect(Geo::ProjectRegistry.find_by_id(@orphaned1.id)).not_to be nil
    end

    it 'removes orphaned registries taking into account FROM_PROJECT_ID' do
      stub_env('FROM_PROJECT_ID' => @orphaned1.project_id, 'TO_PROJECT_ID' => nil)

      run_rake_task('geo:run_orphaned_project_registry_cleaner')

      expect(Geo::ProjectRegistry.count).to be 4
      expect(Geo::ProjectRegistry.find_by_id(@orphaned.id)).not_to be nil
      expect(Geo::ProjectRegistry.find_by_id(@orphaned1.id)).to be nil
    end
  end
end
