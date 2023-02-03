# frozen_string_literal: true

module QA
  RSpec.describe 'Systems', :orchestrated, :geo, product_group: :geo do
    describe 'GitLab HTTP push' do
      let(:file_name) { 'README.md' }

      context 'when regular git commit' do
        it 'is replicated to the secondary',
           testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348050' do
          file_content = 'This is a Geo project! Commit from primary.'
          project = nil

          QA::Flow::Login.while_signed_in(address: :geo_primary) do
            # Create a new Project
            project = Resource::Project.fabricate_via_api! do |project|
              project.name = 'geo-project'
              project.description = 'Geo test project for http push'
            end

            # Perform a git push over HTTP directly to the primary
            Resource::Repository::ProjectPush.fabricate! do |push|
              push.project = project
              push.file_name = file_name
              push.file_content = "# #{file_content}"
              push.commit_message = 'Add README.md'
            end.project.visit!

            # Validate git push worked and file exists with content
            Page::Project::Show.perform do |show|
              show.wait_for_repository_replication

              expect(page).to have_content(file_name)
              expect(page).to have_content(file_content)
            end
          end

          QA::Runtime::Logger.debug('Visiting the secondary geo node')

          QA::Flow::Login.while_signed_in(address: :geo_secondary) do
            Page::Main::Menu.perform(&:go_to_projects)

            Page::Dashboard::Projects.perform do |dashboard|
              dashboard.wait_for_project_replication(project.name)
              dashboard.go_to_project(project.name)
            end

            # Validate the content has been sync'd from the primary
            Page::Project::Show.perform do |show|
              show.wait_for_repository_replication_with(file_name)

              expect(page).to have_content(file_name)
              expect(page).to have_content(file_content)
            end
          end
        end
      end

      context 'when git-lfs commit' do
        it 'is replicated to the secondary',
           testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348049' do
          file_content = 'This is a Geo project!'
          lfs_file_display_message = 'The rendered file could not be displayed because it is stored in LFS.'
          project = nil

          QA::Flow::Login.while_signed_in(address: :geo_primary) do
            project = Resource::Project.fabricate_via_api! do |project|
              project.name = 'geo-project'
              project.description = 'Geo test project for http lfs push'
            end

            # Perform a git push over HTTP directly to the primary
            push = Resource::Repository::ProjectPush.fabricate! do |push|
              push.use_lfs = true
              push.project = project
              push.file_name = file_name
              push.file_content = "# #{file_content}"
              push.commit_message = 'Add README.md'
            end

            expect(push.output).to match(/Locking support detected on remote/)

            # Validate git push worked and file exists with content
            push.project.visit!
            Page::Project::Show.perform do |show|
              show.wait_for_repository_replication

              expect(page).to have_content(file_name)
              expect(page).to have_content(lfs_file_display_message)
            end
          end

          QA::Runtime::Logger.debug('Visiting the secondary geo node')

          QA::Flow::Login.while_signed_in(address: :geo_secondary) do
            Page::Main::Menu.perform(&:go_to_projects)

            Page::Dashboard::Projects.perform do |dashboard|
              dashboard.wait_for_project_replication(project.name)
              dashboard.go_to_project(project.name)
            end

            # Validate the content has been sync'd from the primary
            Page::Project::Show.perform do |show|
              show.wait_for_repository_replication_with(file_name)

              expect(page).to have_content(file_name)
              expect(page).to have_content(lfs_file_display_message)
            end
          end
        end
      end
    end
  end
end
