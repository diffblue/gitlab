# frozen_string_literal: true

module QA
  RSpec.describe 'Geo', :orchestrated, :geo do
    describe 'GitLab Geo attachment replication' do
      let(:file_to_attach) { File.absolute_path(File.join('qa', 'fixtures', 'designs', 'banana_sample.gif')) }

      it 'user uploads attachment to the primary node', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/quality/test_cases/1432' do
        QA::Flow::Login.while_signed_in(address: :geo_primary) do
          @project = Resource::Project.fabricate_via_api! do |project|
            project.name = 'project-for-issues'
            project.description = 'project for adding issues'
          end

          @issue = Resource::Issue.fabricate_via_api! do |issue|
            issue.title = 'My geo issue'
            issue.project = @project
          end

          @issue.visit!

          Page::Project::Issue::Show.perform do |show|
            show.comment('See attached banana for scale', attachment: file_to_attach)
          end
        end

        QA::Runtime::Logger.debug('Visiting the secondary geo node')

        QA::Flow::Login.while_signed_in(address: :geo_secondary) do
          EE::Page::Main::Banner.perform do |banner|
            expect(banner).to have_secondary_read_only_banner
          end

          Page::Main::Menu.perform do |menu|
            menu.go_to_projects
          end

          Page::Dashboard::Projects.perform do |dashboard|
            dashboard.wait_for_project_replication(@project.name)

            dashboard.go_to_project(@project.name)
          end

          Page::Project::Menu.act { click_issues }

          Page::Project::Issue::Index.perform do |index|
            index.wait_for_issue_replication(@issue)
          end

          image_url = find('a[href$="banana_sample.gif"]')[:href]

          Page::Project::Issue::Show.perform do |show|
            found = show.wait_for_attachment_replication(image_url)

            expect(found).to be_truthy
          end
        end
      end
    end
  end
end
