# frozen_string_literal: true

module QA
  RSpec.describe 'Secure', :runner do
    describe 'Security Dashboard in a Project' do
      let(:vulnerability_name) { "CVE-2017-18269 in glibc" }
      let(:vulnerability_description) { "Short description to match in specs" }
      let(:edited_vulnerability_issue_description) { "Test Vulnerability edited comment" }

      before(:all) do
        @executor = "qa-runner-#{Time.now.to_i}"

        Flow::Login.sign_in_unless_signed_in

        @project = Resource::Project.fabricate_via_api! do |p|
          p.name = Runtime::Env.auto_devops_project_name || 'project-with-secure'
          p.description = 'Project with Secure'
          p.auto_devops_enabled = false
          p.initialize_with_readme = true
        end

        @runner = Resource::Runner.fabricate! do |runner|
          runner.project = @project
          runner.name = @executor
          runner.tags = %w[qa test]
        end

        # Push fixture to generate Secure reports
        @source = Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = @project
          push.directory = Pathname
            .new(__dir__)
            .join('../../../../../ee/fixtures/secure_premade_reports')
          push.commit_message = 'Create Secure compatible application to serve premade reports'
          push.branch_name = 'secure-mr'
        end

        @merge_request = Resource::MergeRequest.fabricate_via_api! do |mr|
          mr.project = @project
          mr.source_branch = 'secure-mr'
          mr.target_branch = @project.default_branch
          mr.source = @source
          mr.target = @project.default_branch
          mr.target_new_branch = false
        end

        @merge_request.visit!
        Page::MergeRequest::Show.perform do |merge_request|
          # Give time for the runner on Staging to complete pipeline
          merge_request.has_pipeline_status?('passed')
          merge_request.merge!
        end
        Flow::Pipeline.wait_for_latest_pipeline(pipeline_condition: 'succeeded')

        @label = Resource::ProjectLabel.fabricate_via_api! do |new_label|
          new_label.project = @project
          new_label.title = "test severity 3"
        end
      end

      before do
        Flow::Login.sign_in_unless_signed_in
        @project.visit!
      end

      after(:all) do
        @runner.remove_via_api!
      end

      it 'shows vulnerability details', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/949' do
        Page::Project::Menu.perform(&:click_on_vulnerability_report)

        EE::Page::Project::Secure::SecurityDashboard.perform do |security_dashboard|
          expect(security_dashboard).to have_vulnerability(description: vulnerability_name)
          security_dashboard.click_vulnerability(description: vulnerability_name)
        end

        EE::Page::Project::Secure::VulnerabilityDetails.perform do |vulnerability_details|
          aggregate_failures "testing vulnerability details" do
            expect(vulnerability_details).to have_component(component_name: :vulnerability_header)
            expect(vulnerability_details).to have_component(component_name: :vulnerability_details)
            expect(vulnerability_details).to have_vulnerability_title(title: vulnerability_name)
            expect(vulnerability_details).to have_vulnerability_description(description: vulnerability_description)
            expect(vulnerability_details).to have_component(component_name: :vulnerability_footer)
          end
        end
      end

      it(
        'creates an issue from vulnerability details',
        testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1228'
      ) do
        Page::Project::Menu.perform(&:click_on_vulnerability_report)

        EE::Page::Project::Secure::SecurityDashboard.perform do |security_dashboard|
          expect(security_dashboard).to have_vulnerability(description: vulnerability_name)
          security_dashboard.click_vulnerability(description: vulnerability_name)
        end

        EE::Page::Project::Secure::VulnerabilityDetails.perform do |vulnerability_details|
          expect(vulnerability_details).to have_vulnerability_title(title: vulnerability_name)
          vulnerability_details.click_create_issue_button
        end

        Page::Project::Issue::New.perform do |new_page|
          new_page.fill_description(edited_vulnerability_issue_description)
          new_page.select_label(@label)
          new_page.create_new_issue
        end

        Page::Project::Issue::Show.perform do |issue|
          aggregate_failures "testing edited vulnerability issue" do
            expect(issue).to have_title("Investigate vulnerability: #{vulnerability_name}")
            expect(issue).to have_text(edited_vulnerability_issue_description)
            expect(issue).to have_label(@label.title)
          end
        end
      end
    end
  end
end
