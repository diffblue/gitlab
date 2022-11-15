# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::ElasticsearchController, feature_category: :global_search do
  let(:admin) { create(:admin) }
  let(:helper) { Gitlab::Elastic::Helper.new }

  describe 'POST #enqueue_index' do
    before do
      sign_in(admin)
      allow(Gitlab::Elastic::Helper).to receive(:default).and_return(helper)
    end

    it 'starts indexing' do
      expect(helper).to(receive(:index_exists?)).and_return(true)
      expect_next_instance_of(::Elastic::IndexProjectsService) do |service|
        expect(service).to receive(:execute)
      end

      post :enqueue_index

      expect(controller).to set_flash[:notice].to include('/admin/sidekiq/queues/elastic_commit_indexer')
      expect(response).to redirect_to advanced_search_admin_application_settings_path(anchor: 'js-elasticsearch-settings')
    end

    context 'without an index' do
      before do
        allow(helper).to(receive(:index_exists?)).and_return(false)
      end

      it 'does nothing and returns 404' do
        expect(::Elastic::IndexProjectsService).not_to receive(:new)

        post :enqueue_index

        expect(controller).to set_flash[:warning].to include('create an index before enabling indexing')
        expect(response).to redirect_to advanced_search_admin_application_settings_path(anchor: 'js-elasticsearch-settings')
      end
    end
  end

  describe 'POST #trigger_reindexing' do
    before do
      sign_in(admin)
    end

    it 'creates a reindexing task' do
      expect_next_instance_of(Elastic::ReindexingTask) do |task|
        expect(task).to receive(:save).and_return(true)
      end

      post :trigger_reindexing, params: { elastic_reindexing_task: { elasticsearch_max_slices_running: 60, elasticsearch_slice_multiplier: 2 } }

      expect(controller).to set_flash[:notice].to include('reindexing triggered')
      expect(response).to redirect_to advanced_search_admin_application_settings_path(anchor: 'js-elasticsearch-reindexing')
    end

    it 'does not create a reindexing task if there is another one' do
      allow(Elastic::ReindexingTask).to receive(:current).and_return(build(:elastic_reindexing_task))

      post :trigger_reindexing, params: { elastic_reindexing_task: { elasticsearch_max_slices_running: 60, elasticsearch_slice_multiplier: 2 } }

      expect(controller).to set_flash[:warning].to include('already in progress')
      expect(response).to redirect_to advanced_search_admin_application_settings_path(anchor: 'js-elasticsearch-reindexing')
    end

    it 'does not create a reindexing task if a required param is nil' do
      post :trigger_reindexing, params: { elastic_reindexing_task: { elasticsearch_max_slices_running: nil, elasticsearch_slice_multiplier: 2 } }

      expect(controller).to set_flash[:alert].to include('Elasticsearch reindexing was not started')
      expect(response).to redirect_to advanced_search_admin_application_settings_path(anchor: 'js-elasticsearch-reindexing')
    end
  end

  describe 'POST #cancel_index_deletion' do
    before do
      sign_in(admin)
    end

    let(:task) { create(:elastic_reindexing_task, state: :success, delete_original_index_at: Time.current) }

    it 'sets delete_original_index_at to nil' do
      post :cancel_index_deletion, params: { task_id: task.id }

      expect(task.reload.delete_original_index_at).to be_nil
      expect(controller).to set_flash[:notice].to include('deletion is canceled')
      expect(response).to redirect_to advanced_search_admin_application_settings_path(anchor: 'js-elasticsearch-reindexing')
    end
  end

  describe 'POST #retry_migration' do
    before do
      sign_in(admin)
    end

    let(:migration) { Elastic::DataMigrationService.migrations.last }
    let(:migration_version) { migration.version.to_i }

    it 'deletes the migration record and drops the halted cache' do
      allow(Elastic::MigrationRecord).to receive(:new).and_call_original
      allow(Elastic::MigrationRecord).to receive(:new).with(version: migration.version, name: migration.name, filename: migration.filename).and_return(migration)
      allow(Elastic::DataMigrationService).to receive(:migration_halted?).and_return(false)
      allow(Elastic::DataMigrationService).to receive(:migration_halted?).with(migration).and_return(true, false)
      expect(Elastic::DataMigrationService.halted_migrations?).to be_truthy

      post :retry_migration, params: { version: migration.version }

      expect(Elastic::DataMigrationService.halted_migrations?).to be_falsey
      expect(controller).to set_flash[:notice].to include('Migration has been scheduled to be retried')
      expect(response).to redirect_to advanced_search_admin_application_settings_path(anchor: 'js-elasticsearch-settings')
    end
  end
end
