# frozen_string_literal: true

require 'airborne'

module QA
  RSpec.describe 'Enablement:Search' do
    describe(
      'When using elasticsearch API to search for a public blob',
      :orchestrated,
      :elasticsearch,
      :requires_admin,
      :skip_live_env
    ) do
      let(:api_client) { Runtime::API::Client.new(:gitlab) }

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = "test-project-for-blob-index"
        end
      end

      let(:project_file_content) { "File content for blob index test #{SecureRandom.hex(8)}" }

      let(:elasticsearch_original_state_on?) { Runtime::Search.elasticsearch_on?(api_client) }

      before do
        unless elasticsearch_original_state_on?
          QA::EE::Resource::Settings::Elasticsearch.fabricate_via_api!
        end

        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.add_files([
            { file_path: 'README.md', content: project_file_content }
          ])
        end
      end

      after do
        if !elasticsearch_original_state_on? && !api_client.nil?
          Runtime::Search.disable_elasticsearch(api_client)
        end

        project.remove_via_api!
      end

      it(
        'finds blob that matches file content',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347632'
      ) do
        QA::Support::Retrier.retry_on_exception(
          max_attempts: Runtime::Search::RETRY_MAX_ITERATION,
          sleep_interval: Runtime::Search::RETRY_SLEEP_INTERVAL
        ) do
          get(Runtime::Search.create_search_request(api_client, 'blobs', project_file_content).url)
          aggregate_failures do
            expect_status(QA::Support::API::HTTP_STATUS_OK)
            expect(json_body).not_to be_empty
            expect(json_body[0][:data]).to match(project_file_content)
            expect(json_body[0][:project_id]).to equal(project.id)
          end
        end
      end
    end
  end
end
