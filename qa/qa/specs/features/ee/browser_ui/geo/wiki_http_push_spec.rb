# frozen_string_literal: true

module QA
  RSpec.describe 'Geo', :orchestrated, :geo do
    describe 'GitLab wiki HTTP push' do
      context 'wiki commit' do
        it 'is replicated to the secondary node', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/quality/test_cases/1433' do
          wiki_content = 'This tests replication of wikis via HTTP'
          push_content = 'This is from the Geo wiki push!'
          project = nil

          # Create new wiki and push wiki commit
          QA::Flow::Login.while_signed_in(address: :geo_primary) do
            project = Resource::Project.fabricate_via_api! do |project|
              project.name = 'geo-wiki-http-project'
              project.description = 'Geo project for wiki repo test'
            end

            wiki = Resource::Wiki::ProjectPage.fabricate_via_api! do |wiki|
              wiki.project = project
              wiki.title = 'Geo Replication Wiki'
              wiki.content = wiki_content
            end

            wiki.visit!
            expect(page).to have_content(wiki_content)

            push = Resource::Repository::WikiPush.fabricate! do |push|
              push.wiki = wiki
              push.file_name = 'Home.md'
              push.file_content = push_content
              push.commit_message = 'Update Home.md'
            end

            push.visit!
            expect(page).to have_content(push_content)
          end

          # Validate that wiki is synced on secondary node
          QA::Runtime::Logger.debug('Visiting the secondary geo node')

          QA::Flow::Login.while_signed_in(address: :geo_secondary) do
            EE::Page::Main::Banner.perform do |banner|
              expect(banner).to have_secondary_read_only_banner
            end

            Page::Main::Menu.perform do |menu|
              menu.go_to_projects
            end

            Page::Dashboard::Projects.perform do |dashboard|
              dashboard.wait_for_project_replication(project.name)
              dashboard.go_to_project(project.name)
            end

            Page::Project::Menu.perform(&:click_wiki)

            Page::Project::Wiki::Show.perform do |show|
              expect(show).to have_content(push_content)
            end
          end
        end
      end
    end
  end
end
