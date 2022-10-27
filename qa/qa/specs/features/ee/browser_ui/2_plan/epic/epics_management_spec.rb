# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', :reliable, product_group: :product_planning do
    describe 'Epics Management' do
      before do
        Flow::Login.sign_in
      end

      it 'creates an epic', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347980' do
        epic_title = 'Epic created via GUI'
        EE::Resource::Epic.fabricate_via_browser_ui! do |epic|
          epic.title = epic_title
        end

        expect(page).to have_content(epic_title)
      end

      it 'creates a confidential epic', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347979' do
        epic_title = 'Confidential epic created via GUI'
        EE::Resource::Epic.fabricate_via_browser_ui! do |epic|
          epic.title = epic_title
          epic.confidential = true
        end

        expect(page).to have_content(epic_title)
        expect(page).to have_content("This is a confidential epic.")
      end

      context 'Resources created via API' do
        let(:issue) { create_issue_resource }
        let(:epic)  { create_epic_resource(issue.project.group) }

        context 'Visit epic first' do
          before do
            epic.visit!
          end

          it 'adds/removes issue to/from epic', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347983' do
            EE::Page::Group::Epic::Show.perform do |show|
              show.add_issue_to_epic(issue.web_url)

              expect(show).to have_related_issue_item

              show.remove_issue_from_epic

              expect(show).to have_no_related_issue_item
            end
          end

          it 'comments on epic', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347982' do
            comment = 'My Epic Comment'
            EE::Page::Group::Epic::Show.perform do |show|
              show.comment(comment)

              expect(show).to have_comment(comment)
            end
          end

          it 'closes and reopens an epic', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347984' do
            EE::Page::Group::Epic::Show.perform do |show|
              show.close_reopen_epic

              expect(show).to have_system_note('closed')

              show.close_reopen_epic

              expect(show).to have_system_note('opened')
            end
          end
        end

        it 'adds/removes issue to/from epic using quick actions', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347981' do
          issue.visit!

          Page::Project::Issue::Show.perform do |show|
            show.wait_for_related_issues_to_load
            show.comment("/epic #{issue.project.group.web_url}/-/epics/#{epic.iid}")
            show.comment("/remove_epic")
          end

          epic.visit!

          EE::Page::Group::Epic::Show.perform do |show|
            expect(show).to have_system_note('added issue')
            expect(show).to have_system_note('removed issue')
          end
        end

        def create_issue_resource
          project = Resource::Project.fabricate_via_api! do |project|
            project.name = 'project-for-issues'
            project.description = 'project for adding issues'
            project.visibility = 'private'
          end

          Resource::Issue.fabricate_via_api! do |issue|
            issue.project = project
          end
        end

        def create_epic_resource(group)
          EE::Resource::Epic.fabricate_via_api! do |epic|
            epic.group = group
            epic.title = 'Epic created via API'
          end
        end
      end
    end
  end
end
