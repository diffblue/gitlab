# frozen_string_literal: true

require 'airborne'
require 'securerandom'

module QA
  RSpec.describe 'Enablement:Search' do
    describe 'When using elasticsearch API to search for a public merge request', :orchestrated, :elasticsearch do
      let(:api_client) { Runtime::API::Client.new(:gitlab) }

      let(:merge_request) do
        Resource::MergeRequest.fabricate_via_api! do |mr|
          mr.title = 'Merge request for merge request index test'
          mr.description = "Some merge request description #{SecureRandom.hex(8)}"
        end
      end

      let(:elasticsearch_original_state_on?) { Runtime::Search.elasticsearch_on?(api_client) }

      before do
        unless elasticsearch_original_state_on?
          QA::EE::Resource::Settings::Elasticsearch.fabricate_via_api!
        end
      end

      after do
        if !elasticsearch_original_state_on? && !api_client.nil?
          Runtime::Search.disable_elasticsearch(api_client)
        end

        merge_request.project.remove_via_api!
      end

      it 'finds merge request that matches description', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1867' do
        QA::Support::Retrier.retry_on_exception(max_attempts: Runtime::Search::RETRY_MAX_ITERATION, sleep_interval: Runtime::Search::RETRY_SLEEP_INTERVAL) do
          get Runtime::Search.create_search_request(api_client, 'merge_requests', merge_request.description).url
          expect_status(QA::Support::Api::HTTP_STATUS_OK)

          raise 'Empty search result returned' if json_body.empty?

          expect(json_body[0][:description]).to eq(merge_request.description)
          expect(json_body[0][:project_id]).to eq(merge_request.project.id)
        end
      end
    end
  end
end
