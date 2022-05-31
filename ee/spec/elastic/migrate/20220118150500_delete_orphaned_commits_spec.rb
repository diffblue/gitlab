# frozen_string_literal: true

require 'spec_helper'
require File.expand_path('ee/elastic/migrate/20220118150500_delete_orphaned_commits.rb')

RSpec.describe DeleteOrphanedCommits do
  let(:version) { 20220118150500 }
  let(:migration) { described_class.new(version) }
  let(:helper) { Gitlab::Elastic::Helper.default }
  let(:client) { helper.client }

  describe 'migration_options' do
    it 'has migration options set correctly', :aggregate_failures do
      expect(migration).to be_retry_on_failure
    end
  end

  describe 'completed?' do
    subject { migration.completed? }

    before do
      allow(migration).to receive(:number_of_orphaned_commits).and_return number_of_orphaned_commits
    end

    context 'when there are no more orphaned commits' do
      let(:number_of_orphaned_commits) { 0 }

      it { is_expected.to be_truthy }
    end

    context 'when there are orphaned commits' do
      let(:number_of_orphaned_commits) { 100 }

      it { is_expected.to be_falsey }
    end
  end

  describe 'migrate', :elastic, :sidekiq_inline do
    let(:project) { create(:project, :repository) }

    before do
      stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
      project.repository.index_commits_and_blobs # ensure objects are indexed
      ensure_elasticsearch_index!

      expect(migration).to be_completed # Because no orphaned commits yet
      client.delete(index: migration.index_name, id: "project_#{project.id}", refresh: true)
      expect(migration).not_to be_completed
    end

    context 'when task succeeds' do
      it 'completes the migration' do
        migration.migrate
        wait_for_migration_task_to_complete(migration)
        expect(migration).to be_completed
      end
    end

    context 'when task fails' do
      let(:task_id) { '8675-309' }

      it 'raises an error' do
        allow(migration).to receive(:task_id).and_return task_id
        allow(migration).to receive(:task_failed?).and_return(true)

        expect { migration.migrate }.to raise_error(RuntimeError, /#{task_id}/)
        expect(migration).not_to be_completed
      end
    end
  end

  describe 'task_failed?' do
    it 'returns whether failures are present' do
      task_id = 123
      helper = instance_double(Gitlab::Elastic::Helper)

      allow(migration).to receive(:helper).and_return(helper)
      allow(helper).to receive(:task_status).with(task_id: task_id).and_return({ 'response' => {} })
      expect(migration.task_failed?(task_id: task_id)).to be_falsey

      allow(helper).to receive(:task_status).with(task_id: task_id).and_return({ 'response' => { 'failures' => 456 } })
      expect(migration.task_failed?(task_id: task_id)).to be_truthy
    end
  end

  private

  def wait_for_migration_task_to_complete(migration)
    task_id = migration.task_id
    50.times.each do |attempt| # 5 second timeout duration
      helper.task_status(task_id: task_id)['completed'] ? break : sleep(0.1)
    end
    helper.refresh_index(index_name: migration.index_name)
  end
end
