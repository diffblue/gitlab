# frozen_string_literal: true

module QA
  RSpec.describe 'Systems', :orchestrated, :geo, product_group: :geo do
    describe 'Maven package' do
      include Runtime::Fixtures

      let(:group_id) { 'com.gitlab.qa' }
      let(:artifact_id) { 'maven' }
      let(:package_name) { "#{group_id}/#{artifact_id}".tr('.', '/') }
      let(:auth_token) do
        Flow::Login.sign_in unless Page::Main::Menu.perform(&:signed_in?)

        Resource::PersonalAccessToken.fabricate!.token
      end

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'geo-maven-package-project'
        end
      end

      let(:uri) { URI.parse(Runtime::Scenario.gitlab_address) }
      let(:gitlab_address_with_port) { "#{uri.scheme}://#{uri.host}:#{uri.port}" }

      it 'replicates to the secondary site',
         testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348012' do
        pom_xml = {
          file_path: 'pom.xml',
          content: <<~XML
            <project>
              <groupId>#{group_id}</groupId>
              <artifactId>#{artifact_id}</artifactId>
              <version>1.0</version>
              <modelVersion>4.0.0</modelVersion>
              <repositories>
                <repository>
                  <id>#{project.name}</id>
                  <url>#{gitlab_address_with_port}/api/v4/projects/#{project.id}/packages/maven</url>
                </repository>
              </repositories>
              <distributionManagement>
                <repository>
                  <id>#{project.name}</id>
                  <url>#{gitlab_address_with_port}/api/v4/projects/#{project.id}/packages/maven</url>
                </repository>
                <snapshotRepository>
                  <id>#{project.name}</id>
                  <url>#{gitlab_address_with_port}/api/v4/projects/#{project.id}/packages/maven</url>
                </snapshotRepository>
              </distributionManagement>
            </project>
          XML
        }
        settings_xml = {
          file_path: 'settings.xml',
          content: <<~XML
          <settings xmlns="http://maven.apache.org/SETTINGS/1.1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.1.0 http://maven.apache.org/xsd/settings-1.1.0.xsd">
            <servers>
              <server>
                <id>#{project.name}</id>
                <configuration>
                  <httpHeaders>
                    <property>
                      <name>Private-Token</name>
                      <value>#{auth_token}</value>
                    </property>
                  </httpHeaders>
                </configuration>
              </server>
            </servers>
          </settings>
          XML
        }

        # Use a Maven Docker container to deploy the package
        with_fixtures([pom_xml, settings_xml]) do |dir|
          Service::DockerRun::Maven.new(dir).publish!
        end

        QA::Runtime::Logger.debug('Visiting the secondary Geo site')

        QA::Flow::Login.while_signed_in(address: :geo_secondary) do
          Page::Main::Menu.perform(&:go_to_projects)

          Page::Dashboard::Projects.perform do |dashboard|
            dashboard.wait_for_project_replication(project.name)
            dashboard.go_to_project(project.name)
          end

          # Validate the content has been replicated
          Page::Project::Menu.perform(&:go_to_package_registry)

          Page::Project::Packages::Index.perform do |index|
            index.wait_for_package_replication(package_name)
            index.click_package(package_name)
          end

          Page::Project::Packages::Show.perform do |show|
            expect(show).to have_package_info(package_name, "1.0")
          end
        end
      end
    end
  end
end
