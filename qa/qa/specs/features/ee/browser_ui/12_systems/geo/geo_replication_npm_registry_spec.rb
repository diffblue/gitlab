# frozen_string_literal: true

module QA
  RSpec.describe 'Systems', :orchestrated, :geo, product_group: :geo do
    describe 'npm registry' do
      include Runtime::Fixtures

      let(:uri) { URI.parse(Runtime::Scenario.gitlab_address) }
      let(:gitlab_host_with_port) { "#{uri.host}:#{uri.port}" }
      let(:gitlab_address_with_port) { "#{uri.scheme}://#{uri.host}:#{uri.port}" }
      let(:registry_scope) { project.group.sandbox.path }
      let(:package_name) { "@#{registry_scope}/#{project.name}" }
      let(:version) { "1.0.0" }

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'geo-npm-package-project'
          project.description = 'Geo project for npm package replication test'
        end
      end

      let(:auth_token) do
        QA::Flow::Login.while_signed_in(address: :geo_primary) do
          Resource::PersonalAccessToken.fabricate!.token
        end
      end

      let(:package_json) do
        {
          file_path: 'package.json',
          content: <<~JSON
            {
              "name": "#{package_name}",
              "version": "#{version}",
              "description": "Example package for GitLab npm registry",
              "publishConfig": {
                "@#{registry_scope}:registry": "#{gitlab_address_with_port}/api/v4/projects/#{project.id}/packages/npm/"
              }
            }
          JSON
        }
      end

      let(:npmrc) do
        {
          file_path: '.npmrc',
          content: <<~NPMRC
            //#{gitlab_host_with_port}/api/v4/projects/#{project.id}/packages/npm/:_authToken=#{auth_token}
            //#{gitlab_host_with_port}/api/v4/packages/npm/:_authToken=#{auth_token}
            @#{registry_scope}:registry=#{gitlab_address_with_port}/api/v4/packages/npm/
          NPMRC
        }
      end

      # Test code is based on qa/specs/features/browser_ui/5_package/npm_registry_spec.rb
      it 'replicates npm registry to secondary Geo site',
         testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348085' do
        # Use a Node Docker container to publish the package
        with_fixtures([npmrc, package_json]) do |dir|
          Service::DockerRun::NodeJs.new(dir).publish!
        end

        QA::Runtime::Logger.debug('Visiting the secondary Geo site')

        QA::Flow::Login.while_signed_in(address: :geo_secondary) do
          Page::Main::Menu.perform(&:go_to_projects)

          Page::Dashboard::Projects.perform do |dashboard|
            dashboard.wait_for_project_replication(project.name)
            dashboard.go_to_project(project.name)
          end

          Page::Project::Menu.perform(&:go_to_package_registry)

          Page::Project::Packages::Index.perform do |index|
            index.wait_for_package_replication(package_name)
            index.click_package(package_name)
          end

          Page::Project::Packages::Show.perform do |show|
            expect(show).to have_package_info(package_name, version)
          end
        end
      end
    end
  end
end
