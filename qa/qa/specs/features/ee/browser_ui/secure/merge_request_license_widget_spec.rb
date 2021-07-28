# frozen_string_literal: true

require 'pathname'

module QA
  RSpec.describe 'Secure', :runner do
    describe 'License merge request widget' do
      let(:approved_license_name) { "MIT License" }
      let(:denied_license_name) { "zlib License" }
      let(:executor) {"qa-runner-#{Time.now.to_i}"}

      after do
        @runner.remove_via_api!
      end

      before do
        Flow::Login.sign_in

        @project = Resource::Project.fabricate_via_api! do |project|
          project.name = 'license-widget-project'
          project.description = 'License widget test'
        end

        @runner = Resource::Runner.fabricate! do |runner|
          runner.project = @project
          runner.name = executor
          runner.tags = %w[qa test]
        end

        Resource::Repository::ProjectPush.fabricate! do |project_push|
          project_push.project = @project
          project_push.directory = Pathname
            .new(__dir__)
            .join('../../../../../ee/fixtures/secure_license_files')
          project_push.commit_message = 'Create license file'
        end

        @project.visit!
        Flow::Pipeline.wait_for_latest_pipeline(pipeline_condition: 'succeeded')

        @merge_request = Resource::MergeRequest.fabricate_via_api! do |mr|
          mr.project = @project
          mr.source_branch = 'license-management-mr'
          mr.target_branch = @project.default_branch
          mr.target = @project.default_branch
          mr.file_name = 'gl-license-scanning-report.json'
          mr.file_content =
            <<~FILE_UPDATE
            {
              "version": "2.1",
              "licenses": [
                {
                  "id": "Apache-2.0",
                  "name": "Apache License 2.0",
                  "url": "http://www.apache.org/licenses/LICENSE-2.0.html"
                },
                {
                  "id": "MIT",
                  "name": "MIT License",
                  "url": "https://opensource.org/licenses/MIT"
                },
                {
                  "id": "Zlib",
                  "name": "zlib License",
                  "url": "https://opensource.org/licenses/Zlib"
                }
              ],
              "dependencies": [
                {
                  "name": "actioncable",
                  "version": "6.0.3.3",
                  "package_manager": "bundler",
                  "path": "Gemfile.lock",
                  "licenses": ["MIT"]
                },
                {
                  "name": "test_package",
                  "version": "0.1.0",
                  "package_manager": "bundler",
                  "path": "Gemfile.lock",
                  "licenses": ["Apache-2.0"]
                },
                {
                  "name": "zlib",
                  "version": "1.2.11",
                  "package_manager": "bundler",
                  "path": "Gemfile.lock",
                  "licenses": ["Zlib"]
                }
              ]
            }
            FILE_UPDATE
          mr.target_new_branch = false
        end

        @project.visit!
        Flow::Pipeline.wait_for_latest_pipeline(pipeline_condition: 'succeeded')
      end

      it 'manage licenses from the merge request', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/575' do
        @merge_request.visit!

        Page::MergeRequest::Show.perform do |show|
          # Give time for the runner to complete pipeline
          show.has_pipeline_status?('passed')

          # TODO: Remove the reload_page: once https://gitlab.com/gitlab-org/gitlab/-/issues/335227 is fixed
          Support::Retrier.retry_until(max_attempts: 5, sleep_interval: 5, reload_page: show) do
            show.wait_for_license_compliance_report
          end

          show.click_manage_licenses_button
        end

        EE::Page::Project::Secure::LicenseCompliance.perform do |license_compliance|
          license_compliance.open_tab
          license_compliance.approve_license approved_license_name
          license_compliance.deny_license denied_license_name
        end

        @merge_request.visit!

        Page::MergeRequest::Show.perform do |show|
          show.wait_for_license_compliance_report
          show.expand_license_report
          expect(show).to have_approved_license approved_license_name
          expect(show).to have_denied_license denied_license_name
        end
      end
    end
  end
end
