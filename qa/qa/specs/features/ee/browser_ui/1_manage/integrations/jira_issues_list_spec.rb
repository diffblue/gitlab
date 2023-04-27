# frozen_string_literal: true

module QA
  RSpec.describe 'Manage' do
    describe 'Jira issues integration', :jira, :orchestrated, :requires_admin, product_group: :import_and_integrate do
      # rubocop:disable RSpec/InstanceVariable
      before(:context) do
        jira_project_key = Vendor::Jira::JiraAPI.perform(&:create_project)

        @project = Resource::Project.fabricate_via_api! do |project|
          project.name = "jira_issue_list"
        end

        @summary_one = "Summary #{SecureRandom.hex(6)}"
        @description_one = 'First Description'

        @summary_two = "Summary #{SecureRandom.hex(6)}"
        @description_two = 'Second Description'

        @issue_key_one = Vendor::Jira::JiraAPI.perform do |jira|
          jira.create_issue(jira_project_key, issue_type: 'Task', summary: @summary_one, description: @description_one)
        end

        @issue_key_two = Vendor::Jira::JiraAPI.perform do |jira|
          jira.create_issue(jira_project_key, issue_type: 'Task', summary: @summary_two, description: @description_two)
        end

        setup_jira_integration(jira_project_key)
      end

      before do
        login!

        Page::Project::Menu.perform(&:go_to_jira_issues)
        EE::Page::Project::Issue::Jira::Index.perform(&:wait_for_loading)
      end

      it(
        'searching issues returns results',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348238'
      ) do
        EE::Page::Project::Issue::Jira::Index.perform do |jira_index_page|
          jira_index_page.search_issues(@summary_one)
        end

        issues = EE::Page::Project::Issue::Jira::Index.perform(&:visible_issues).map(&:text)

        aggregate_failures do
          expect(issues.size).to be(1)
          expect(issues).to include(match(/#{@issue_key_one}/))
        end
      end

      it 'shows open issues', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348237' do
        issues = EE::Page::Project::Issue::Jira::Index.perform(&:visible_issues).map(&:text)

        aggregate_failures do
          expect(issues.size).to be(2)
          expect(issues).to include(match(/#{@issue_key_one}/), match(/#{@issue_key_two}/))
        end
      end

      it(
        'views an issue',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348236'
      ) do
        EE::Page::Project::Issue::Jira::Index.perform do |jira_index_page|
          jira_index_page.click_issue(@issue_key_two)
        end

        EE::Page::Project::Issue::Jira::Show.perform do |jira_show_page|
          expect(jira_show_page.summary_content).to eql(@summary_two)
          expect(jira_show_page.description_content).to eql(@description_two)
        end
      end

      def login!
        page.visit Runtime::Scenario.gitlab_address
        Flow::Login.sign_in_unless_signed_in

        @project.visit!
      end

      def setup_jira_integration(jira_project_key)
        url = Vendor::Jira::JiraAPI.perform(&:base_url)

        Runtime::ApplicationSettings.set_application_settings(allow_local_requests_from_web_hooks_and_services: true)

        login!

        Page::Project::Menu.perform(&:go_to_integrations_settings)
        QA::Page::Project::Settings::Integrations.perform(&:click_jira_link)

        QA::Page::Project::Settings::Services::Jira.perform do |jira|
          jira.setup_service_with(url: url) do |service|
            service.enable_jira_issues
            service.set_jira_project_key(jira_project_key)
          end
        end
      end
      # rubocop:enable RSpec/InstanceVariable
    end
  end
end
