# frozen_string_literal: true

module QA
  RSpec.describe 'Secure', :runner do
    let(:number_of_dependencies_in_fixture) { 13 }
    let(:dependency_scan_example_vuln) { 'Prototype pollution attack in mixin-deep' }
    let(:container_scan_example_vuln) { 'CVE-2017-18269 in glibc' }
    let(:sast_scan_example_vuln) { 'Cipher with no integrity' }
    let(:dast_scan_example_vuln) { 'Cookie Without SameSite Attribute' }
    let(:sast_scan_fp_example_vuln) { "Possible unprotected redirect" }
    let(:sast_scan_fp_example_vuln_desc) { "Possible unprotected redirect near line 46" }

    describe 'Security Reports' do
      before(:context) do
        @project = Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-with-secure'
          project.description = 'Project with Secure'
          project.group = Resource::Group.fabricate_via_api!
        end
      end

      before do
        Flow::Login.sign_in_unless_signed_in
        @project.visit!
      end

      after(:context) do
        @project&.remove_via_api! if @project
      end

      it 'dependency list has empty state', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348004' do
        Page::Project::Menu.perform(&:click_on_dependency_list)

        EE::Page::Project::Secure::DependencyList.perform do |dependency_list|
          expect(dependency_list).to have_empty_state_description('The dependency list details information about the components used within your project.')
          expect(dependency_list).to have_link('More Information', href: %r{\/help\/user\/application_security\/dependency_list\/index})
        end
      end

      context 'populated reports are displayed' do
        before(:context) do
          Flow::Login.sign_in_unless_signed_in

          @runner = Resource::Runner.fabricate_via_api! do |runner|
            runner.project = @project
            runner.name = "runner-for-#{@project.name}"
            runner.tags = ['secure_report']
          end

          # Push fixture to generate Secure reports
          Resource::Repository::ProjectPush.fabricate! do |project_push|
            project_push.project = @project
            project_push.directory = Pathname
              .new(__dir__)
              .join('../../../../../ee/fixtures/secure_premade_reports')
            project_push.commit_message = 'Create Secure compatible application to serve premade reports'
          end.project.visit!

          Flow::Pipeline.wait_for_latest_pipeline(pipeline_condition: 'succeeded')
        end

        after(:context) do
          @runner&.remove_via_api! if @runner
        end

        it 'displays security reports in the pipeline', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348036' do
          Flow::Pipeline.visit_latest_pipeline
          Page::Project::Pipeline::Show.perform do |pipeline|
            pipeline.click_on_security

            filter_report_and_perform(pipeline, "Dependency Scanning") do
              expect(pipeline).to have_vulnerability_info_content dependency_scan_example_vuln
            end

            filter_report_and_perform(pipeline, "Container Scanning") do
              expect(pipeline).to have_vulnerability_info_content container_scan_example_vuln
            end

            filter_report_and_perform(pipeline, "SAST") do
              expect(pipeline).to have_vulnerability_info_content sast_scan_example_vuln
              expect(pipeline).to have_vulnerability_info_content sast_scan_fp_example_vuln
            end

            filter_report_and_perform(pipeline, "DAST") do
              expect(pipeline).to have_vulnerability_info_content dast_scan_example_vuln
            end
          end
        end

        it 'displays security reports in the project security dashboard', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348037' do
          Page::Project::Menu.perform(&:click_project)
          Page::Project::Menu.perform(&:click_on_vulnerability_report)

          EE::Page::Project::Secure::Show.perform do |dashboard|
            filter_report_and_perform(dashboard, "Dependency Scanning") do
              expect(dashboard).to have_vulnerability dependency_scan_example_vuln
            end

            filter_report_and_perform(dashboard, "Container Scanning") do
              expect(dashboard).to have_vulnerability container_scan_example_vuln
            end

            filter_report_and_perform(dashboard, "SAST") do
              expect(dashboard).to have_vulnerability sast_scan_example_vuln
              expect(dashboard).to have_vulnerability sast_scan_fp_example_vuln
              expect(dashboard).to have_false_positive_vulnerability
            end

            filter_report_and_perform(dashboard, "DAST") do
              expect(dashboard).to have_vulnerability dast_scan_example_vuln
            end
          end
        end

        it 'displays security reports in the group security dashboard', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348038' do
          Page::Main::Menu.perform(&:go_to_groups)
          Page::Dashboard::Groups.perform do |groups|
            groups.click_group @project.group.path
          end
          Page::Group::Menu.perform(&:click_group_security_link)

          EE::Page::Group::Secure::Show.perform do |dashboard|
            expect(dashboard).to have_security_status_project_for_severity('F', @project)
          end

          Page::Group::Menu.perform(&:click_group_vulnerability_link)

          EE::Page::Group::Secure::Show.perform do |dashboard|
            dashboard.filter_project(@project.name)

            filter_report_and_perform(dashboard, "Dependency Scanning") do
              expect(dashboard).to have_vulnerability dependency_scan_example_vuln
            end

            filter_report_and_perform(dashboard, "Container Scanning") do
              expect(dashboard).to have_vulnerability container_scan_example_vuln
            end

            filter_report_and_perform(dashboard, "SAST") do
              expect(dashboard).to have_vulnerability sast_scan_example_vuln
            end

            filter_report_and_perform(dashboard, "DAST") do
              expect(dashboard).to have_vulnerability dast_scan_example_vuln
            end
          end
        end

        it 'displays false positives for the vulnerabilities', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/350412' do
          Page::Project::Menu.perform(&:click_project)
          Page::Project::Menu.perform(&:click_on_vulnerability_report)

          EE::Page::Project::Secure::Show.perform do |security_dashboard|
            filter_report_and_perform(security_dashboard, "SAST") do
              expect(security_dashboard).to have_vulnerability sast_scan_fp_example_vuln
            end
          end

          EE::Page::Project::Secure::SecurityDashboard.perform do |security_dashboard|
            security_dashboard.click_vulnerability(description: sast_scan_fp_example_vuln)
          end

          EE::Page::Project::Secure::VulnerabilityDetails.perform do |vulnerability_details|
            aggregate_failures "testing False positive vulnerability details" do
              expect(vulnerability_details).to have_component(component_name: :vulnerability_header)
              expect(vulnerability_details).to have_component(component_name: :vulnerability_details)
              expect(vulnerability_details).to have_vulnerability_title(title: sast_scan_fp_example_vuln)
              expect(vulnerability_details).to have_vulnerability_description(description: sast_scan_fp_example_vuln_desc)
              expect(vulnerability_details).to have_component(component_name: :vulnerability_footer)
              expect(vulnerability_details).to have_component(component_name: :false_positive_alert)
            end
          end
        end

        it 'displays the Dependency List', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348035' do
          Page::Project::Menu.perform(&:click_on_dependency_list)

          EE::Page::Project::Secure::DependencyList.perform do |dependency_list|
            expect(dependency_list).to have_dependency_count_of number_of_dependencies_in_fixture
          end
        end
      end

      def filter_report_and_perform(page, report)
        page.filter_report_type report
        yield
        page.filter_report_type report # Disable filter to avoid combining
      end
    end
  end
end
