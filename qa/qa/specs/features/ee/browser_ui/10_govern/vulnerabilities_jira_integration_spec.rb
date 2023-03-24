# frozen_string_literal: true

module QA
  RSpec.describe 'Govern', :jira, :orchestrated, :requires_admin, product_group: :threat_insights do
    describe 'vulnerability report with jira integration',
testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/377406' do
      let(:jira_project_key) { 'JITP' }
      let!(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'vulnerabilities-jira-integration'
          project.description = 'Project with vulnerabilities for JIRA integration test'
          project.initialize_with_readme = true
        end
      end

      let(:vulnerabilities) do
        { "Cricket vulnerability": "Describes a game with a bat and a ball",
          "Football vulnerability": "Describes a ball and two goal posts",
          "Basketball vulnerability": "Describes a ball and two hoops",
          "Tennis vulnerability": "Describes a ball two rackets and a net" }
      end

      let!(:vulnerability_report) do
        vulnerabilities.each do |name, description|
          QA::EE::Resource::VulnerabilityItem.fabricate_via_api! do |vulnerability|
            vulnerability.id = project.id
            vulnerability.severity = vuln_severity
            vulnerability.name = name
            vulnerability.description = description
          end
        end
      end

      let(:vuln_name) { "Cricket vulnerability" }
      let(:vuln_severity) { :CRITICAL }
      let(:jira_issue_summary) { "Investigate vulnerability: #{vuln_name}" }
      let(:jira_host) { Vendor::Jira::JiraAPI.perform(&:base_url) }

      before do
        Flow::Login.sign_in
        project.visit!
        set_up_jira_integration
      end

      it 'can successfully create a JIRA issue from vulnerability details page',
         testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/381386' do
        Page::Project::Menu.perform(&:go_to_vulnerability_report)

        EE::Page::Project::Secure::SecurityDashboard.perform do |security_dashboard|
          expect(security_dashboard).to have_vulnerability(description: vuln_name)

          security_dashboard.click_vulnerability(description: vuln_name)
        end

        EE::Page::Project::Secure::VulnerabilityDetails.perform(&:click_create_jira_issue_button)
        jira_description = ""
        switch_to_jira_tab

        QA::Vendor::Jira::JiraIssuePage.perform do |jira|
          jira.login_if_required(Runtime::Env.jira_admin_username, Runtime::Env.jira_admin_password)
          expect(jira.summary_field).to eq(jira_issue_summary)
          expect(jira.issue_description).to include(vulnerabilities[vuln_name.to_sym])
          jira_description = jira.issue_description
          expect(jira_description).to include("Severity: #{vuln_severity.to_s.downcase}")
        end

        issue_key = QA::Vendor::Jira::JiraAPI.perform do |jira_api|
          jira_api.create_issue(jira_project_key, summary: jira_issue_summary,
                                                  description: jira_description)
        end

        switch_to_vulnerability_report_tab
        page.refresh

        jira_link = "#{jira_host}/browse/#{issue_key}"
        EE::Page::Project::Secure::VulnerabilityDetails.perform do |vulnerability|
          expect(vulnerability.jira_issue_link_present?(jira_issue_summary, jira_link, issue_key)).to be true
        end
      end

      def switch_to_jira_tab
        page.driver.browser.switch_to.window(page.driver.browser.window_handles.last)
      end

      def switch_to_vulnerability_report_tab
        page.driver.browser.switch_to.window(page.driver.browser.window_handles.first)
      end

      def set_up_jira_integration
        Runtime::ApplicationSettings.set_application_settings(allow_local_requests_from_web_hooks_and_services: true)

        page.visit Runtime::Scenario.gitlab_address
        Flow::Login.sign_in_unless_signed_in

        project.visit!

        Page::Project::Menu.perform(&:go_to_integrations_settings)
        QA::Page::Project::Settings::Integrations.perform(&:click_jira_link)

        QA::Page::Project::Settings::Services::Jira.perform do |jira|
          jira.setup_service_with(url: jira_host)
          jira.enable_jira_issues
          jira.set_jira_project_key(jira_project_key)
          jira.enable_jira_vulnerabilities
          jira.select_vulnerability_bug_type("Bug")
          jira.click_save_changes_and_wait
        end

        expect(page).not_to have_text("Url is blocked")
        expect(page).to have_text("Jira settings saved and active.")
      end
    end
  end
end
