# frozen_string_literal: true

module QA
  RSpec.describe 'Secure', :runner, product_group: :composition_analysis,
    only: { subdomain: %i[staging staging-canary] } do
    describe 'License Scanning' do
      let!(:test_project) do
        create(:project, :with_readme, name: 'license-scanning-project', description: 'License Scanning Project')
      end

      let!(:licenses) do
        ['Academic Free License v2.1', 'Apache License 2.0', 'BSD 2-Clause "Simplified" License',
          'BSD 3-Clause "New" or "Revised" License', 'BSD Zero Clause License',
          'Creative Commons Attribution 3.0 Unported', 'Creative Commons Zero v1.0 Universal',
          'ISC License', 'MIT License', 'The Unlicense', 'unknown']
      end

      let!(:runner) do
        create(:project_runner,
          project: test_project,
          name: "runner-for-#{test_project.name}",
          tags: ['secure_license_scanning'],
          executor: :docker)
      end

      let!(:source) do
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = test_project
          commit.branch = 'license-management-mr'
          commit.start_branch = test_project.default_branch
          commit.add_files([
            {
              file_path: '.gitlab-ci.yml',
              content: File.read(
                File.join(EE::Runtime::Path.fixtures_path, 'secure_license_scanning_files',
                  '.gitlab-ci.yml')
              )
            },
            {
              file_path: 'package.json',
              content: File.read(
                File.join(
                  EE::Runtime::Path.fixtures_path,
                  'secure_license_scanning_files',
                  'package.json'
                )
              )
            },
            {
              file_path: 'package-lock.json',
              content: File.read(
                File.join(
                  EE::Runtime::Path.fixtures_path,
                  'secure_license_scanning_files',
                  'package-lock'
                )
              )
            }
          ])
        end
      end

      after do
        runner&.remove_via_api!
      end

      context 'when populated by a Dependency Scan' do
        it 'populates licenses in the pipeline, dashboard and merge request',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/409969' do
          merge_request = Resource::MergeRequest.fabricate_via_api! do |merge_request|
            merge_request.source = source
            merge_request.project = test_project
            merge_request.source_branch = 'license-management-mr'
            merge_request.target_branch = test_project.default_branch
          end
          Flow::Login.sign_in_unless_signed_in

          merge_request.visit!

          Page::MergeRequest::Show.perform do |mr|
            mr.wait_for_license_compliance_report
            mr.expand_license_report
            licenses.each do |license|
              expect(mr).to have_license(license)
            end
            mr.merge_immediately!
          end

          Flow::Pipeline.wait_for_latest_pipeline(status: 'Passed', wait: 600)

          test_project.visit!
          Flow::Pipeline.visit_latest_pipeline
          Page::Project::Pipeline::Show.perform do |pipeline|
            pipeline.click_on_licenses
            licenses.each do |license|
              expect(pipeline).to have_license(license)
            end
          end
          test_project.visit!
          Page::Project::Menu.perform(&:go_to_license_compliance)
          EE::Page::Project::Secure::LicenseCompliance.perform do |license_compliance|
            expect(license_compliance).to have_licenses_on_paginated_table(licenses)
          end
        end
      end
    end
  end
end
