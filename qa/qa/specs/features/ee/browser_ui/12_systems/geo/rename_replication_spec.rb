# frozen_string_literal: true

module QA
  RSpec.describe 'Systems', :orchestrated, :geo, product_group: :geo do
    describe 'GitLab Geo project rename replication' do
      let(:geo_project_renamed) { "geo-after-rename-#{SecureRandom.hex(8)}" }

      it 'user renames project',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348055' do
        original_project_name = 'geo-before-rename'
        original_readme_content = "The original project name was #{original_project_name}"
        readme_file_name = 'README.md'

        # create the project and push code
        QA::Flow::Login.while_signed_in(address: :geo_primary) do
          project = Resource::Project.fabricate_via_api! do |project|
            project.name = original_project_name
            project.description = 'Geo project to be renamed'
          end

          geo_project_name = project.name

          Resource::Repository::ProjectPush.fabricate! do |push|
            push.project = project
            push.file_name = readme_file_name
            push.file_content = original_readme_content
            push.commit_message = "Add #{readme_file_name}"
          end

          # rename the project
          Page::Main::Menu.act { go_to_projects }

          Page::Dashboard::Projects.perform do |dashboard|
            dashboard.go_to_project(geo_project_name)
          end

          Page::Project::Menu.act { click_settings }

          Page::Project::Settings::Main.perform do |settings|
            settings.rename_project_to(geo_project_renamed)
            expect(settings).to have_breadcrumb(geo_project_renamed)

            settings.expand_advanced_settings do |advanced_settings|
              advanced_settings.update_project_path_to(geo_project_renamed)
            end
          end
        end

        # check renamed project exist on secondary node
        QA::Runtime::Logger.debug('Visiting the secondary geo node')

        QA::Flow::Login.while_signed_in(address: :geo_secondary) do
          Page::Main::Menu.perform(&:go_to_projects)

          Page::Dashboard::Projects.perform do |dashboard|
            dashboard.wait_for_project_replication(geo_project_renamed)

            dashboard.go_to_project(geo_project_renamed)
          end

          Page::Project::Show.perform do |show|
            show.wait_for_repository_replication

            expect(page).to have_content readme_file_name
            expect(page).to have_content original_readme_content
          end
        end
      end
    end
  end
end
