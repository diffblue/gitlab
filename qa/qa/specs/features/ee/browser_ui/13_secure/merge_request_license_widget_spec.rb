# frozen_string_literal: true

module QA
  RSpec.describe 'Secure', :runner, product_group: :composition_analysis, feature_flag: {
    name: 'license_scanning_sbom_scanner'
  }, quarantine: {
    type: :waiting_on,
    issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/397067'
  } do
    describe 'License merge request widget' do
      describe 'when a license scanning report exists' do
        let(:approved_license_name) { "MIT License" }
        let(:denied_license_name) { "zlib License" }
        let(:executor) { "qa-runner-#{Time.now.to_i}" }

        after do
          @runner.remove_via_api!
        end

        before do
          Flow::Login.sign_in

          @project = Resource::Project.fabricate_via_api! do |project|
            project.name = 'license-widget-project'
            project.description = 'License widget test'
          end

          @runner = Resource::ProjectRunner.fabricate! do |runner|
            runner.project = @project
            runner.name = executor
            runner.tags = ['secure_license']
          end

          Resource::Repository::Commit.fabricate_via_api! do |resource|
            resource.project = @project
            resource.commit_message = 'Create license file'
            resource.add_directory(Pathname.new(File.join(EE::Runtime::Path.fixtures_path, 'secure_license_files')))
          end

          @project.visit!
          Flow::Pipeline.wait_for_latest_pipeline(status: 'passed', wait: 180)

          @merge_request = Resource::MergeRequest.fabricate_via_api! do |mr|
            mr.project = @project
            mr.source_branch = 'license-management-mr'
            mr.target_branch = @project.default_branch
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
            mr.update_existing_file = true
          end

          @project.visit!
          Flow::Pipeline.wait_for_latest_pipeline(status: 'passed', wait: 180)
        end

        it 'manage licenses from the merge request',
           testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348039' do
          @merge_request.visit!

          Page::MergeRequest::Show.perform do |show|
            # Give time for the runner to complete pipeline
            show.has_pipeline_status?('passed')

            Support::Retrier.retry_until(max_attempts: 5, sleep_interval: 5) do
              show.wait_for_license_compliance_report
            end

            show.click_manage_licenses_button
          end

          EE::Page::Project::Secure::LicenseCompliance.perform do |license_compliance|
            license_compliance.open_tab
            license_compliance.approve_license(approved_license_name)
            license_compliance.deny_license(denied_license_name)
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

      describe 'when a CycloneDX SBOM file exists', only: { subdomain: :staging } do
        let(:approved_license_name) { "CC0-1.0" }
        let(:denied_license_name) { "Apache-2.0" }
        let(:executor) { "qa-runner-#{Time.now.to_i}" }

        after do
          @runner.remove_via_api!
        end

        before do
          Flow::Login.sign_in

          @project = Resource::Project.fabricate_via_api! do |project|
            project.name = 'license-widget-project'
            project.description = 'License widget test'
          end
          Runtime::Feature.enable(:license_scanning_sbom_scanner, project: @project)

          @runner = Resource::ProjectRunner.fabricate! do |runner|
            runner.project = @project
            runner.name = executor
            runner.tags = ['secure_sbom']
          end

          Resource::Repository::Commit.fabricate_via_api! do |resource|
            resource.project = @project
            resource.commit_message = 'Create sbom file'
            resource.add_directory(Pathname.new(File.join(EE::Runtime::Path.fixtures_path, 'secure_sbom_files')))
          end

          @project.visit!
          Flow::Pipeline.wait_for_latest_pipeline(status: 'passed', wait: 180)

          @merge_request = Resource::MergeRequest.fabricate_via_api! do |mr|
            mr.project = @project
            mr.source_branch = 'license-management-mr'
            mr.target_branch = @project.default_branch
            mr.file_name = 'gl-sbom-npm-npm.cdx.json'
            mr.file_content =
              <<~FILE_UPDATE
              {
                "bomFormat": "CycloneDX",
                "specVersion": "1.4",
                "serialNumber": "urn:uuid:aec33827-20ae-40d0-ae83-18ee846364d2",
                "version": 1,
                "metadata": {
                  "timestamp": "2022-02-23T08:01:37Z",
                  "tools": [
                    {
                      "vendor": "GitLab",
                      "name": "Gemnasium",
                      "version": "2.34.0"
                    }
                  ],
                  "authors": [
                    {
                      "name": "GitLab",
                      "email": "support@gitlab.com"
                    }
                  ],
                  "properties": [
                    {
                      "name": "gitlab:dependency_scanning:input_file",
                      "value": "package-lock.json"
                    },
                    {
                      "name": "gitlab:dependency_scanning:package_manager",
                      "value": "npm"
                    }
                  ]
                },
                "components": [
                  {
                    "name": "dragselect",
                    "version": "1.3.6",
                    "purl": "pkg:npm/dragselect@1.3.6",
                    "type": "library"
                  },
                  {
                    "name": "@polkadot/rpc-augment",
                    "version": "8.4.1",
                    "purl": "pkg:npm/@polkadot/rpc-augment@8.4.1",
                    "type": "library"
                  },
                  {
                    "name": "spdx-license-list",
                    "version": "6.6.0",
                    "purl": "pkg:npm/spdx-license-list@6.6.0",
                    "type": "library"
                  }
                ]
              }
              FILE_UPDATE
            mr.target_new_branch = false
            mr.update_existing_file = true
          end

          @project.visit!
          Flow::Pipeline.wait_for_latest_pipeline(status: 'passed', wait: 180)
        end

        it 'manage licenses from the merge request',
           testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/394713' do
          @merge_request.visit!

          Page::MergeRequest::Show.perform do |show|
            # Give time for the runner to complete pipeline
            show.has_pipeline_status?('passed')

            Support::Retrier.retry_until(max_attempts: 5, sleep_interval: 5) do
              show.wait_for_license_compliance_report
            end

            show.click_manage_licenses_button
          end

          EE::Page::Project::Secure::LicenseCompliance.perform do |license_compliance|
            license_compliance.open_tab
            license_compliance.approve_license(approved_license_name)
            license_compliance.deny_license(denied_license_name)
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
end
