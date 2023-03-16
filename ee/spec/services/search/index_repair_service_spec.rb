# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Search::IndexRepairService, feature_category: :global_search do
  let_it_be(:project) { create(:project, :repository) }

  subject(:service) { described_class.execute(project) }

  shared_examples_for 'does no index repair work' do
    it 'does not call the search client' do
      expect(::Gitlab::Search::Client).not_to receive(:new)

      service
    end
  end

  describe '.execute' do
    context 'when search_index_integrity feature flag is disabled' do
      before do
        stub_feature_flags(search_index_integrity: false)
      end

      it_behaves_like 'does no index repair work'
    end

    context 'when project.should_check_index_integrity? is false' do
      before do
        allow(project).to receive(:should_check_index_integrity?).and_return(false)
      end

      it_behaves_like 'does no index repair work'
    end

    context 'when blobs exist in the index', :elastic_delete_by_query, :sidekiq_inline do
      before do
        stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)

        project.repository.index_commits_and_blobs

        ensure_elasticsearch_index!
      end

      it 'gets a count from the search client but does not log anything' do
        expect_next_instance_of(::Gitlab::Search::Client) do |client|
          expect(client).to receive(:count).and_call_original
        end
        expect(::Gitlab::Elasticsearch::Logger).not_to receive(:build)

        service
      end
    end

    context 'when no blobs exist in the index', :elastic_delete_by_query do
      before do
        stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
      end

      it 'logs a warning' do
        create(:project_statistics, project: project, repository_size: 100)

        expect_next_instance_of(::Gitlab::Search::Client) do |client|
          expected_body = {
            query: {
              bool: {
                filter: [
                  {
                    term: {
                      type: 'blob'
                    }
                  },
                  {
                    term: {
                      project_id: project.id
                    }
                  }
                ]
              }
            }
          }

          expect(client).to receive(:count).with(index: 'gitlab-test', body: expected_body).and_call_original
        end

        expect_next_instance_of(::Gitlab::Elasticsearch::Logger) do |logger|
          expected_hash = {
            message: 'blob documents missing from index for project',
            class: 'Search::IndexRepairService',
            namespace_id: project.namespace_id,
            root_namespace_id: project.root_namespace.id,
            project_id: project.id,
            project_commit: project.commit,
            project_last_repository_updated_at: project.last_repository_updated_at,
            index_status_last_commit: nil,
            index_status_indexed_at: nil,
            repository_size: 100
          }.stringify_keys
          expect(logger).to receive(:warn).with(a_hash_including(expected_hash))
        end

        service
      end
    end
  end
end
