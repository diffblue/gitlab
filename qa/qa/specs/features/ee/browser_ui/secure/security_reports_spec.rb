# frozen_string_literal: true

require 'pathname'

module QA
  RSpec.describe 'Secure', :runner do
    let(:number_of_dependencies_in_fixture) { 9 }
    let(:dependency_scan_example_vuln) { 'Prototype pollution attack in mixin-deep' }
    let(:container_scan_example_vuln) { 'CVE-2017-18269 in glibc' }
    let(:sast_scan_example_vuln) { 'Cipher with no integrity' }
    let(:dast_scan_example_vuln) { 'Cookie Without SameSite Attribute' }

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

      it 'dependency list has empty state', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1787' do
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

        it 'displays security reports in the pipeline', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1777' do
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
            end

            filter_report_and_perform(pipeline, "DAST") do
              expect(pipeline).to have_vulnerability_info_content dast_scan_example_vuln
            end
          end
        end

        it 'displays security reports in the project security dashboard', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1683' do
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
            end

            filter_report_and_perform(dashboard, "DAST") do
              expect(dashboard).to have_vulnerability dast_scan_example_vuln
            end
          end
        end

        it 'displays security reports in the group security dashboard', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1280' do
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

        it 'displays the Dependency List', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/564' do
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
