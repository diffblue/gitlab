# frozen_string_literal: true

module QA
  RSpec.describe 'Secure', :runner, product_group: :composition_analysis do
    describe 'License Compliance' do
      before(:all) do
        @project = Resource::Project.fabricate_via_api! do |project|
          project.name = Runtime::Env.auto_devops_project_name || 'project-with-secure'
          project.description = 'Project with Secure'
        end
      end

      after(:all) do
        @project&.remove_via_api! if @project
      end

      it 'has empty state', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347681' do
        Flow::Login.sign_in_unless_signed_in
        @project.visit!
        Page::Project::Menu.perform(&:click_on_license_compliance)

        EE::Page::Project::Secure::LicenseCompliance.perform do |license_compliance|
          aggregate_failures do
            expect(license_compliance).to have_empty_state_description('The license list details information about the licenses used within your project.')
            expect(license_compliance).to have_link('More Information', href: %r{\/help\/user\/compliance\/license_compliance\/index})
          end
        end
      end

      context 'License Management' do
        approved_license_name = 'MIT License'
        denied_license_name = 'Apache License 2.0'

        before(:context) do
          @runner = Resource::Runner.fabricate_via_api! do |runner|
            runner.project = @project
            runner.name = "runner-for-#{@project.name}"
            runner.tags = ['secure_license']
          end
          # Push fixture to generate Secure reports
          Resource::Repository::ProjectPush.fabricate! do |project_push|
            project_push.project = @project
            project_push.files = [{ name: '.gitlab-ci.yml',
                                    content: File.read(
                                      Pathname
                                       .new(__dir__)
                                       .join('../../../../../ee/fixtures/secure_license_files/.gitlab-ci.yml')) },
                                  { name: 'gl-license-scanning-report.json',
                                    content: File.read(
                                      Pathname
                                       .new(__dir__)
                                       .join('../../../../../ee/fixtures/secure_premade_reports/gl-license-scanning-report.json')) }]
            project_push.commit_message = 'Create Secure compatible application to serve premade reports'
          end
          Flow::Login.sign_in_unless_signed_in
          @project.visit!
          Flow::Pipeline.wait_for_latest_pipeline(status: 'passed')
          @project.visit!
          Page::Project::Menu.perform(&:click_on_license_compliance)
          EE::Page::Project::Secure::LicenseCompliance.perform do |license_compliance|
            license_compliance.open_tab
            license_compliance.approve_license(approved_license_name)
            license_compliance.deny_license(denied_license_name)
          end
        end

        before do
          Flow::Login.sign_in_unless_signed_in
          @project.visit!
          Page::Project::Menu.perform(&:click_on_license_compliance)
        end

        after(:context) do
          @runner&.remove_via_api!
        end

        it 'can approve a license in the settings page', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348078' do
          EE::Page::Project::Secure::LicenseCompliance.perform do |license_compliance|
            license_compliance.open_tab
            expect(license_compliance).to have_approved_license(approved_license_name)
          end
        end

        it 'can deny a license in the settings page', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348077' do
          EE::Page::Project::Secure::LicenseCompliance.perform do |license_compliance|
            license_compliance.open_tab
            expect(license_compliance).to have_denied_license(denied_license_name)
          end
        end

        describe 'Pipeline Licence tab', only: { subdomain: %i[staging production pre staging-canary] } do
          it 'can approve and deny licenses in the pipeline', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348079' do
            @project.visit!
            Flow::Pipeline.visit_latest_pipeline

            Page::Project::Pipeline::Show.perform do |pipeline|
              pipeline.click_on_licenses

              aggregate_failures do
                expect(pipeline).to have_approved_license(approved_license_name)
                expect(pipeline).to have_denied_license(denied_license_name)
              end
            end
          end
        end
      end
    end
  end
end
