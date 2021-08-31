# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Search using Elasticsearch', :orchestrated, :elasticsearch, :requires_admin, quarantine: { issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/332210', type: :investigating } do
      include Runtime::Fixtures
      let(:project_name) { 'testing_elasticsearch_indexing' }
      let(:project_file_name) { 'elasticsearch.rb' }
      let(:project_file_content) { 'elasticsearch: true' }
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = project_name
        end
      end

      before(:all) do
        Flow::Login.while_signed_in_as_admin do
          QA::EE::Resource::Settings::Elasticsearch.fabricate_via_browser_ui!
        end

        Runtime::Search.assert_elasticsearch_responding
      end

      before do
        Flow::Login.sign_in

        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = project
          push.file_name = project_file_name
          push.file_content = project_file_content
        end.project.visit!
      end

      it 'tests reindexing after push', retry: 3, testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/quality/test_cases/1445' do
        expect { Runtime::Search.find_code(project_file_name, project_file_content) }.not_to raise_error

        QA::Page::Main::Menu.perform do |menu|
          menu.search_for(project_file_content)
        end

        Page::Search::Results.perform do |search|
          search.switch_to_code

          expect(search).to have_file_with_content project_file_name, project_file_content
        end
      end

      it 'tests reindexing after webIDE', retry: 3, testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/quality/test_cases/1444' do
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

        QA::Support::Retrier.retry_on_exception(max_attempts: Runtime::Search::RETRY_MAX_ITERATION, sleep_interval: Runtime::Search::RETRY_SLEEP_INTERVAL) do
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
