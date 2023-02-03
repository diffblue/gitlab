# frozen_string_literal: true

module QA
  RSpec.describe 'Systems', :orchestrated, :geo, product_group: :geo do
    describe 'GitLab wiki SSH push to secondary' do
      wiki_content = 'This tests replication of wikis via SSH to secondary'
      push_content = 'This is from the Geo wiki push via SSH to secondary!'
      wiki = nil
      key = nil
      project = nil

      before do
        QA::Flow::Login.while_signed_in(address: :geo_primary) do
          # Create a new SSH key
          key = Resource::SSHKey.fabricate_via_api! do |resource|
            resource.title = "Geo wiki SSH to 2nd #{Time.now.to_f}"
            resource.expires_at = Date.today + 2
          end

          # Create a new project and wiki
          project = Resource::Project.fabricate_via_api! do |project|
            project.name = 'geo-wiki-ssh2-project'
            project.description = 'Geo project for wiki SSH spec'
          end

          wiki = Resource::Wiki::ProjectPage.fabricate_via_api! do |wiki|
            wiki.project = project
            wiki.title = 'Geo Replication Wiki'
            wiki.content = wiki_content
          end

          wiki.visit!
          validate_content(wiki_content)
        end
      end

      after do
        key.remove_via_api!
      end

      it 'proxies wiki commit to primary node and ultmately replicates to secondary node',
         testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348054' do
        QA::Runtime::Logger.debug('*****Visiting the secondary geo node*****')

        QA::Flow::Login.while_signed_in(address: :geo_secondary) do
          # Ensure the SSH key has replicated
          expect(key).to be_replicated

          Page::Main::Menu.perform(&:go_to_projects)

          Page::Dashboard::Projects.perform do |dashboard|
            dashboard.wait_for_project_replication(project.name)
            dashboard.go_to_project(project.name)
          end

          Page::Project::Menu.perform(&:click_wiki)

          # Grab the SSH URI for the secondary node and store as 'secondary_location'
          Page::Project::Wiki::Show.perform do |show|
            show.wait_for_repository_replication
            show.click_clone_repository
          end

          secondary_location = Page::Project::Wiki::GitAccess.perform do |git_access|
            git_access.choose_repository_clone_ssh
            git_access.repository_location
          end

          # Perform a git push over SSH to the secondary node
          push = Resource::Repository::WikiPush.fabricate! do |push|
            push.ssh_key = key
            push.wiki = wiki
            push.repository_ssh_uri = secondary_location.uri
            push.file_name = 'Home.md'
            push.file_content = push_content
            push.commit_message = 'Update Home.md'
          end

          # Validate git push worked and new content is visible
          push.visit!

          Page::Project::Wiki::Show.perform do |show|
            show.wait_for_repository_replication_with(push_content)
            show.refresh
          end

          validate_content(push_content)
        end
      end

      private

      def validate_content(content)
        Page::Project::Wiki::Show.perform do |show|
          expect(show).to have_content(content)
        end
      end
    end
  end
end
