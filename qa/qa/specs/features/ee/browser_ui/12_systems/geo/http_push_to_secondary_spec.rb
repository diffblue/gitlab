# frozen_string_literal: true

module QA
  RSpec.describe 'Systems', :orchestrated, :geo, product_group: :geo do
    let(:git_push_http_path_prefix) { '/-/push_from_secondary' }

    describe 'GitLab Geo HTTP push secondary' do
      let(:file_content_primary) { 'This is a Geo project! Commit from primary.' }
      let(:file_content_secondary) { 'This is a Geo project! Commit from secondary.' }

      context 'when regular git commit' do
        it 'is redirected to the primary and ultimately replicated to the secondary',
           testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348060' do
          file_name = 'README.md'
          project = nil

          QA::Flow::Login.while_signed_in(address: :geo_primary) do
            # Create a new Project
            project = Resource::Project.fabricate_via_api! do |project|
              project.name = 'geo-project'
              project.description = 'Geo test project for http push to 2nd'
            end

            # Perform a git push over HTTP directly to the primary
            #
            # This push is required to ensure we have the primary credentials
            # written out to the .netrc
            Resource::Repository::ProjectPush.fabricate! do |push|
              push.project = project
              push.file_name = file_name
              push.file_content = "# #{file_content_primary}"
              push.commit_message = "Add #{file_name}"
            end
            project.visit!
          end

          QA::Runtime::Logger.debug('Visiting the secondary geo node')

          QA::Flow::Login.while_signed_in(address: :geo_secondary) do
            Page::Main::Menu.perform(&:go_to_projects)

            Page::Dashboard::Projects.perform do |dashboard|
              dashboard.wait_for_project_replication(project.name)
              dashboard.go_to_project(project.name)
            end

            # Grab the HTTP URI for the secondary and store as 'location'
            location = Page::Project::Show.perform do |project_page|
              project_page.wait_for_repository_replication
              project_page.repository_clone_http_location
            end

            # Perform a git push over HTTP at the secondary
            Resource::Repository::Push.fabricate! do |push|
              push.new_branch = false
              push.repository_http_uri = location.uri
              push.file_name = file_name
              push.file_content = "# #{file_content_secondary}"
              push.commit_message = "Update #{file_name}"
            end

            # Validate git push worked and new content is visible
            Page::Project::Show.perform do |show|
              show.wait_for_repository_replication_with(file_content_secondary)
              show.refresh

              expect(page).to have_content(file_name)
              expect(page).to have_content(file_content_secondary)
            end
          end
        end
      end

      context 'when git-lfs commit' do
        it 'is redirected to the primary and ultimately replicated to the secondary',
           testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348059' do
          file_name_primary = 'README.md'
          file_name_secondary = 'README_MORE.md'
          project = nil

          QA::Flow::Login.while_signed_in(address: :geo_primary) do
            # Create a new Project
            project = Resource::Project.fabricate_via_api! do |project|
              project.name = 'geo-project'
              project.description = 'Geo test project for http lfs push to 2nd'
            end

            # Perform a git push over HTTP directly to the primary
            #
            # This push is required to ensure we have the primary credentials
            # written out to the .netrc
            Resource::Repository::Push.fabricate! do |push|
              push.use_lfs = true
              push.repository_http_uri = project.repository_http_location.uri
              push.file_name = file_name_primary
              push.file_content = "# #{file_content_primary}"
              push.commit_message = "Add #{file_name_primary}"
            end
          end

          QA::Runtime::Logger.debug('Visiting the secondary geo node')

          QA::Flow::Login.while_signed_in(address: :geo_secondary) do
            Page::Main::Menu.perform(&:go_to_projects)

            Page::Dashboard::Projects.perform do |dashboard|
              dashboard.wait_for_project_replication(project.name)
              dashboard.go_to_project(project.name)
            end

            # Grab the HTTP URI for the secondary and store as 'location'
            location = Page::Project::Show.perform do |project_page|
              project_page.wait_for_repository_replication
              project_page.repository_clone_http_location
            end

            # Perform a git push over HTTP at the secondary
            Resource::Repository::Push.fabricate! do |push|
              push.use_lfs = true
              push.new_branch = false
              push.repository_http_uri = location.uri
              push.file_name = file_name_secondary
              push.file_content = "# #{file_content_secondary}"
              push.commit_message = "Add #{file_name_secondary}"
            end

            # Validate git push worked and new content is visible
            Page::Project::Show.perform do |show|
              show.wait_for_repository_replication_with(file_name_secondary)
              show.refresh

              expect(page).to have_content(file_name_secondary)
            end
          end
        end
      end
    end
  end
end
