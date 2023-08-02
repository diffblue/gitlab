# frozen_string_literal: true

module QA
  RSpec.describe 'Secure', :runner, product_group: :composition_analysis,
    only: { subdomain: %i[staging staging-canary] } do
    describe 'License Scanning' do
      let!(:test_project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'license-scanning-project'
          project.description = 'License Scanning Project'
        end
      end

      let!(:licenses) do
        ['Academic Free License v2.1', 'Apache License 2.0', 'BSD 2-Clause "Simplified" License',
          'BSD 3-Clause "New" or "Revised" License', 'BSD Zero Clause License',
          'Creative Commons Attribution 3.0 Unported', 'Creative Commons Zero v1.0 Universal',
          'ISC License', 'MIT License', 'The Unlicense', 'unknown']
      end

      let!(:runner) do
        Resource::ProjectRunner.fabricate_via_api! do |runner|
          runner.project = test_project
          runner.name = "runner-for-#{test_project.name}"
          runner.tags = ['secure_license_scanning']
          runner.executor = :docker
        end
      end

      before do
        Resource::Repository::ProjectPush.fabricate! do |project_push|
          project_push.project = test_project
          project_push.files = [
            {
              name: '.gitlab-ci.yml',
              content: File.read(
                File.join(EE::Runtime::Path.fixtures_path, 'secure_license_scanning_files',
                  '.gitlab-ci.yml')
              )
            },
            {
              name: 'package.json',
              content: File.read(
                File.join(
                  EE::Runtime::Path.fixtures_path,
                  'secure_license_scanning_files',
                  'package.json'
                )
              )
            },
            {
              name: 'package-lock.json',
              content: File.read(
                File.join(
                  EE::Runtime::Path.fixtures_path,
                  'secure_license_scanning_files',
                  'package-lock'
                )
              )
            }
          ]
          project_push.commit_message = 'NPM Package and Package Lock files'
        end
        Flow::Login.sign_in_unless_signed_in

        test_project.visit!
        Flow::Pipeline.wait_for_latest_pipeline(status: 'passed', wait: 600)
      end

      after do
        runner&.remove_via_api!
      end

      context 'when populated by a Dependency Scan' do
        it 'populates licenses in the pipeline',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/409969' do
          Flow::Login.sign_in_unless_signed_in
          test_project.visit!
          Flow::Pipeline.visit_latest_pipeline
          Page::Project::Pipeline::Show.perform do |pipeline|
            pipeline.click_on_licenses
            licenses.each do |license|
              expect(pipeline).to have_license(license)
            end
          end
        end

        it 'populates licenses in the dashboard',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/409967' do
          Flow::Login.sign_in_unless_signed_in
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
