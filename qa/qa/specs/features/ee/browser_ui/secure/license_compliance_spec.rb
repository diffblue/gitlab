# frozen_string_literal: true

module QA
  RSpec.describe 'Secure', :runner do
    let(:approved_license_name) { "MIT License" }
    let(:denied_license_name) { "Apache License 2.0" }

    context 'License Compliance page' do
      before(:context) do
        @project = Resource::Project.fabricate_via_api! do |project|
          project.name = Runtime::Env.auto_devops_project_name || 'project-with-secure'
          project.description = 'Project with Secure'
        end

        @runner = Resource::Runner.fabricate! do |runner|
          runner.project = @project
          runner.name = "runner-for-#{@project.name}"
          runner.tags = ['secure_license']
        end
      end

      after(:context) do
        @runner&.remove_via_api! if @runner
        @project&.remove_via_api! if @project
      end

      before do
        Flow::Login.sign_in_unless_signed_in
        @project.visit!
        Page::Project::Menu.perform(&:click_on_license_compliance)
      end

      it 'has empty state', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1128' do
        EE::Page::Project::Secure::LicenseCompliance.perform do |license_compliance|
          expect(license_compliance).to have_empty_state_description('The license list details information about the licenses used within your project.')
          expect(license_compliance).to have_link('More Information', href: %r{\/help\/user\/compliance\/license_compliance\/index})
        end
      end

      describe 'approve or deny licenses' do
        before(:context) do
          Flow::Login.sign_in_unless_signed_in

          # Push fixture to generate Secure reports
          Resource::Repository::ProjectPush.fabricate! do |project_push|
            project_push.project = @project
            project_push.directory = Pathname
              .new(__dir__)
              .join('../../../../../ee/fixtures/secure_license_files')
            project_push.commit_message = 'Create Secure compatible application to serve premade reports'
          end.project.visit!

          Flow::Pipeline.wait_for_latest_pipeline(pipeline_condition: 'succeeded')
        end

        it 'can approve a license in the settings page', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/964' do
          EE::Page::Project::Secure::LicenseCompliance.perform do |license_compliance|
            license_compliance.open_tab
            license_compliance.approve_license approved_license_name

            expect(license_compliance).to have_approved_license approved_license_name
          end
        end

        it 'can deny a license in the settings page', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/963' do
          EE::Page::Project::Secure::LicenseCompliance.perform do |license_compliance|
            license_compliance.open_tab
            license_compliance.deny_license denied_license_name

            expect(license_compliance).to have_denied_license denied_license_name
          end
        end
      end
    end

    context 'License Compliance pipeline reports', quarantine: { issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/284658', type: :bug } do
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = Runtime::Env.auto_devops_project_name || 'project-with-secure'
          project.description = 'Project with Secure'
        end
      end

      let(:runner) do
        Resource::Runner.fabricate! do |runner|
          runner.project = project
          runner.name = "runner-for-#{project.name}"
          runner.tags = %w[qa test]
        end
      end

      before(:context) do
        Flow::Login.sign_in_unless_signed_in

        # Push fixture to generate Secure reports
        Resource::Repository::ProjectPush.fabricate! do |project_push|
          project_push.project = project
          project_push.directory = Pathname
            .new(__dir__)
            .join('../../../../../ee/fixtures/secure_premade_reports')
          project_push.commit_message = 'Create Secure compatible application to serve premade reports'
        end.project.visit!

        Flow::Pipeline.wait_for_latest_pipeline(pipeline_condition: 'succeeded')
        Page::Project::Menu.perform(&:click_on_license_compliance)
      end

      after do
        runner&.remove_via_api! if runner
        project&.remove_via_api! if project
      end

      it 'can approve and deny licenses in the pipeline', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1767' do
        EE::Page::Project::Secure::LicenseCompliance.perform do |license_compliance|
          license_compliance.open_tab
          license_compliance.approve_license approved_license_name
          license_compliance.deny_license denied_license_name
        end

        project.visit!
        Flow::Pipeline.visit_latest_pipeline

        Page::Project::Pipeline::Show.perform do |pipeline|
          pipeline.click_on_licenses

          aggregate_failures do
            expect(pipeline).to have_approved_license approved_license_name
            expect(pipeline).to have_denied_license denied_license_name
          end
        end
      end
    end
  end
end
