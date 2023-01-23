# frozen_string_literal: true

require 'airborne'

module QA
  RSpec.describe 'Data Stores', product_group: :global_search do
    describe(
      'When using elasticsearch API to search for a known blob',
      :orchestrated,
      :elasticsearch,
      except: :production
    ) do
      include_context 'advanced search active'

      let(:project_file_content) { "elasticsearch: #{SecureRandom.hex(8)}" }
      let(:non_member_user) do
        Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_1)
      end

      let(:api_client) { Runtime::API::Client.new(:gitlab) }
      let(:non_member_api_client) do
        Runtime::API::Client.new(
          user: non_member_user,
          personal_access_token: Runtime::Env.gitlab_qa_access_token_1
        )
      end

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = "api-es-#{SecureRandom.hex(8)}"
        end
      end

      before do
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.add_files(
            [{
              file_path: 'README.md', content: project_file_content
            }]
          )
        end
      end

      it(
        'searches public project and finds a blob as an non-member user',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348063'
      ) do
        successful_search(non_member_api_client)
      end

      describe 'When searching a private repository' do
        before do
          project.set_visibility(:private)
        end

        it(
          'finds a blob as an authorized user',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348064'
        ) do
          successful_search(api_client)
        end

        it(
          'does not find a blob as an non-member user',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348065'
        ) do
          QA::Support::Retrier.retry_on_exception(
            max_attempts: Runtime::Search::RETRY_MAX_ITERATION,
            sleep_interval: Runtime::Search::RETRY_SLEEP_INTERVAL
          ) do
            get(Runtime::Search.create_search_request(non_member_api_client, 'blobs', project_file_content).url)
            aggregate_failures do
              expect_status(QA::Support::API::HTTP_STATUS_OK)
              expect(json_body).to be_empty
            end
          end
        end
      end

      private

      def successful_search(api_client)
        QA::Support::Retrier.retry_on_exception(
          max_attempts: Runtime::Search::RETRY_MAX_ITERATION,
          sleep_interval: Runtime::Search::RETRY_SLEEP_INTERVAL
        ) do
          get(Runtime::Search.create_search_request(api_client, 'blobs', project_file_content).url)
          expect_status(QA::Support::API::HTTP_STATUS_OK)
          aggregate_failures do
            expect(json_body).not_to be_empty
            expect(json_body[0][:data]).to match(project_file_content)
            expect(json_body[0][:project_id]).to equal(project.id)
          end
        end
      end
    end
  end
end
