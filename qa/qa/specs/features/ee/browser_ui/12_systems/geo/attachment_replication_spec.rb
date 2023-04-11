# frozen_string_literal: true

module QA
  RSpec.describe 'Systems', :orchestrated, :geo, product_group: :geo do
    describe 'GitLab Geo attachment replication' do
      let(:file_to_attach) { File.join(Runtime::Path.fixtures_path, 'designs', 'banana_sample.gif') }
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-for-issues'
          project.description = 'project for adding issues'
        end
      end

      let(:issue) do
        Resource::Issue.fabricate_via_api! do |issue|
          issue.title = 'My geo issue'
          issue.project = project
        end
      end

      it 'user uploads attachment to the primary node',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348052' do
        QA::Flow::Login.while_signed_in(address: :geo_primary) do
          issue.visit!

          Page::Project::Issue::Show.perform do |show|
            show.comment('See attached banana for scale', attachment: file_to_attach)
          end
        end

        QA::Runtime::Logger.debug('Visiting the secondary geo node')

        QA::Flow::Login.while_signed_in(address: :geo_secondary) do
          Page::Main::Menu.perform(&:go_to_projects)

          Page::Dashboard::Projects.perform do |dashboard|
            dashboard.wait_for_project_replication(project.name)

            dashboard.go_to_project(project.name)
          end

          Page::Project::Menu.act { go_to_issues }

          Page::Project::Issue::Index.perform do |index|
            index.wait_for_issue_replication(issue)
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
