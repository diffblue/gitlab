# frozen_string_literal: true

module QA
  RSpec.describe 'Data Stores', product_group: :global_search, quarantine: {
    issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/385927',
    type: :stale
  } do
    describe(
      'Search using Elasticsearch',
      :orchestrated,
      :elasticsearch,
      :requires_admin,
      :skip_live_env
    ) do
      include Runtime::Fixtures
      let(:api_client) { Runtime::API::Client.new(:gitlab) }
      let(:project_file_name) { 'elasticsearch.rb' }
      let(:project_file_content) { "Some file content #{SecureRandom.hex(8)}" }
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'testing_elasticsearch_indexing'
        end
      end

      let(:elasticsearch_original_state_on?) { Runtime::Search.elasticsearch_on?(api_client) }

      before do
        QA::EE::Resource::Settings::Elasticsearch.fabricate_via_api! unless elasticsearch_original_state_on?

        Runtime::Search.assert_elasticsearch_responding

        Flow::Login.sign_in

        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = project
          push.file_name = project_file_name
          push.file_content = project_file_content
        end.project.visit!
      end

      it(
        'tests reindexing after push',
        retry: 3,
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348040'
      ) do
        expect { Runtime::Search.find_code(project_file_name, project_file_content) }.not_to raise_error

        QA::Page::Main::Menu.perform do |menu|
          menu.search_for(project_file_content)
        end

        Page::Search::Results.perform do |search|
          search.switch_to_code

          expect(search).to have_file_with_content project_file_name, project_file_content
        end
      end

      it(
        'tests reindexing after webIDE',
        retry: 3,
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347629'
      ) do
        template = {
          file_name: 'LICENSE',
          name: 'Mozilla Public License 2.0',
          api_path: 'licenses',
          api_key: 'mpl-2.0'
        }
        content = fetch_template_from_api(template[:api_path], template[:api_key])

        Page::Project::Show.perform(&:open_web_ide!)
        Page::Project::WebIDE::Edit.perform do |ide|
          ide.create_new_file_from_template template[:file_name], template[:name]
          ide.commit_changes
        end

        expect { Runtime::Search.find_code(template[:file_name], content[0..33]) }.not_to raise_error

        Page::Main::Menu.perform(&:go_to_groups)

        QA::Page::Main::Menu.perform do |menu|
          menu.search_for content[0..33]
        end

        QA::Support::Retrier
          .retry_on_exception(
            max_attempts: Runtime::Search::RETRY_MAX_ITERATION, sleep_interval: Runtime::Search::RETRY_SLEEP_INTERVAL
          ) do
          Page::Search::Results.perform do |search|
            search.switch_to_code
            aggregate_failures "testing expectations" do
              expect(search).to have_file_in_project template[:file_name], project.name
              expect(search).to have_file_with_content template[:file_name], content[0..33]
            end
          end
        end
      end
    end
  end
end
