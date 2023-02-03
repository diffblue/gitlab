# frozen_string_literal: true

module QA
  RSpec.describe 'Systems', :orchestrated, :geo, product_group: :geo do
    describe 'GitLab wiki SSH push' do
      key = nil

      after do
        key&.remove_via_api!
      end

      context 'when wiki commit' do
        it 'is replicated to the secondary',
           testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348048' do
          wiki_content = 'This tests replication of wikis via SSH'
          push_content = 'This is from the Geo wiki push via SSH!'
          project = nil

          QA::Flow::Login.while_signed_in(address: :geo_primary) do
            # Create a new SSH key
            key = Resource::SSHKey.fabricate_via_api! do |resource|
              resource.title = "Geo wiki SSH #{Time.now.to_f}"
              resource.expires_at = Date.today + 2
            end

            # Create a new project and wiki
            project = Resource::Project.fabricate_via_api! do |project|
              project.name = 'geo-wiki-ssh-project'
              project.description = 'Geo project for wiki SSH spec'
            end

            wiki = Resource::Wiki::ProjectPage.fabricate_via_api! do |wiki|
              wiki.project = project
              wiki.title = 'Geo Replication Wiki'
              wiki.content = wiki_content
            end

            wiki.visit!
            validate_content(wiki_content)

            # Perform a git push over SSH directly to the primary
            pushed_wiki = Resource::Repository::WikiPush.fabricate! do |push|
              push.ssh_key = key
              push.wiki = wiki
              push.file_name = 'Home.md'
              push.file_content = push_content
              push.commit_message = 'Update Home.md'
            end

            pushed_wiki.visit!
            validate_content(push_content)
          end

          QA::Runtime::Logger.debug('*****Visiting the secondary geo node*****')

          QA::Flow::Login.while_signed_in(address: :geo_secondary) do
            Page::Main::Menu.perform(&:go_to_projects)

            Page::Dashboard::Projects.perform do |dashboard|
              dashboard.wait_for_project_replication(project.name)
              dashboard.go_to_project(project.name)
            end

            # Validate git push worked and new content is visible
            Page::Project::Menu.perform(&:click_wiki)

            Page::Project::Wiki::Show.perform do |show|
              show.wait_for_repository_replication_with(push_content)
              show.refresh
            end

            validate_content(push_content)
          end
        end
      end

      def validate_content(content)
        Page::Project::Wiki::Show.perform do |show|
          expect(show).to have_content(content)
        end
      end
    end
  end
end
