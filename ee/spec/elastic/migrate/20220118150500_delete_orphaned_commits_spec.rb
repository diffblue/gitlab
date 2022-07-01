# frozen_string_literal: true

require 'spec_helper'
require File.expand_path('ee/elastic/migrate/20220118150500_delete_orphaned_commits.rb')

RSpec.describe DeleteOrphanedCommits do
  include ElasticsearchHelpers

  let(:version) { 20220118150500 }
  let(:migration) { described_class.new(version) }
  let(:helper) { Gitlab::Elastic::Helper.default }
  let(:client) { helper.client }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    set_elasticsearch_migration_to :delete_orphaned_commits, including: false
  end

  describe 'migration_options' do
    it 'has migration options set correctly', :aggregate_failures do
      expect(migration).to be_retry_on_failure
    end
  end

  describe 'completed?', :elastic, :sidekiq_inline do
    let(:project) { create(:project, :repository) }

    subject { migration.completed? }

    before do
      project.repository.index_commits_and_blobs # ensure objects are indexed
      ensure_elasticsearch_index!
    end

    context 'when there are no more orphaned commits' do
      it { is_expected.to be_truthy }
    end

    context 'when there are commits missing parent join and visibility level' do
      before do
        client.delete(index: migration.index_name, id: "project_#{project.id}", refresh: true) # remove parent project
        first_ten_commits = project.repository.commits(nil, limit: 10)
        remove_permission_data_for_commits(first_ten_commits) # remove permission data for commits
      end

      it { is_expected.to be_falsey }
    end

    context 'when there are commits missing only parent join' do
      before do
        client.delete(index: migration.index_name, id: "project_#{project.id}", refresh: true) # remove parent project
      end

      it { is_expected.to be_truthy }
    end
  end

  describe 'migrate', :elastic, :sidekiq_inline do
    let(:project) { create(:project, :repository) }

    before do
      project.repository.index_commits_and_blobs # ensure objects are indexed
      ensure_elasticsearch_index!

      expect(migration).to be_completed # Because no orphaned commits yet
      client.delete(index: migration.index_name, id: "project_#{project.id}", refresh: true) # remove parent project
      first_ten_commits = project.repository.commits(nil, limit: 10)
      remove_permission_data_for_commits(first_ten_commits) # remove permission data for commits
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

  def remove_permission_data_for_commits(commits)
    script =  {
      source: "ctx._source.remove('visibility_level'); ctx._source.remove('repository_access_level');"
    }

    update_by_query(commits, script)
  end

  def update_by_query(commits, script)
    commit_ids = commits.map { |i| i.id }

    client = Repository.__elasticsearch__.client
    client.update_by_query({
                             index: Repository.__elasticsearch__.index_name,
                             wait_for_completion: true, # run synchronously
                             refresh: true, # make operation visible to search
                             body: {
                               script: script,
                               query: {
                                 bool: {
                                   must: [
                                     {
                                       terms: {
                                         'commit.sha': commit_ids
                                       }
                                     },
                                     {
                                       term: {
                                         type: {
                                           value: 'commit'
                                         }
                                       }
                                     }
                                   ]
                                 }
                               }
                             }
                           })
  end
end
