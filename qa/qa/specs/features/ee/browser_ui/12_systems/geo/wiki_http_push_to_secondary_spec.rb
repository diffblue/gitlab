# frozen_string_literal: true

module QA
  # https://gitlab.com/gitlab-org/gitlab/issues/35706
  RSpec.describe 'Systems', :orchestrated, :geo, product_group: :geo do
    describe 'GitLab Geo Wiki HTTP push secondary' do
      let(:wiki_content) { 'This tests wiki pushes via HTTP to secondary.' }
      let(:push_content_secondary) { 'This is from the Geo wiki push to secondary!' }
      let(:git_push_http_path_prefix) { '/-/push_from_secondary' }

      wiki = nil
      project = nil

      it 'is redirected to the primary and ultimately replicated to the secondary',
         testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348053' do
        QA::Flow::Login.while_signed_in(address: :geo_primary) do
          # Create a new project and wiki
          project = Resource::Project.fabricate_via_api! do |project|
            project.name = 'geo-wiki-http2-project'
            project.description = 'Geo test project'
          end

          wiki = Resource::Wiki::ProjectPage.fabricate_via_api! do |wiki|
            wiki.project = project
            wiki.title = 'Geo wiki'
            wiki.content = wiki_content
          end

          wiki.visit!
          expect(wiki).to have_content(wiki_content)

          # Perform a git push over HTTP directly to the primary
          # This push is required to ensure we have the primary credentials
          # written out to the .netrc
          Resource::Repository::WikiPush.fabricate! do |push|
            push.wiki = wiki
            push.file_name = 'Readme.md'
            push.file_content = 'This is from the Geo wiki push to primary!'
            push.commit_message = 'Update Readme.md'
          end
        end

        QA::Runtime::Logger.debug('Visiting the secondary geo node')

        QA::Flow::Login.while_signed_in(address: :geo_secondary) do
          Page::Main::Menu.perform(&:go_to_projects)

          Page::Dashboard::Projects.perform do |dashboard|
            dashboard.wait_for_project_replication(project.name)
            dashboard.go_to_project(project.name)
          end

          Page::Project::Menu.perform(&:click_wiki)

          # Grab the HTTP URI for the secondary node and store as 'secondary_location'
          Page::Project::Wiki::Show.perform do |show|
            show.wait_for_repository_replication
            show.click_clone_repository
          end

          secondary_location = Page::Project::Wiki::GitAccess.perform do |git_access|
            git_access.choose_repository_clone_http
            git_access.repository_location
          end

          # Perform a git push over HTTP to the secondary node
          push = Resource::Repository::WikiPush.fabricate! do |push|
            push.wiki = wiki
            push.repository_http_uri = secondary_location.uri
            push.file_name = 'Home.md'
            push.file_content = push_content_secondary
            push.commit_message = 'Update Home.md'
          end

          # Validate git push worked and new content is visible
          push.visit!

          Page::Project::Wiki::Show.perform do |show|
            show.wait_for_repository_replication_with(push_content_secondary)
            show.refresh

            expect(show).to have_content(push_content_secondary)
          end
        end
      end
    end
  end
end
