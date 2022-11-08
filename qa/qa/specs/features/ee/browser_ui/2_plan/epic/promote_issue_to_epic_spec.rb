# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', :reliable, product_group: :product_planning do
    describe 'promote issue to epic' do
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'promote-issue-to-epic'
          project.description = 'Project to promote issue to epic'
        end
      end

      let(:issue) do
        Resource::Issue.fabricate_via_api! do |issue|
          issue.project = project
        end
      end

      before do
        Flow::Login.sign_in
      end

      it 'promotes issue to epic', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347970' do
        issue.visit!

        Page::Project::Issue::Show.perform do |show|
          # Due to the randomness of tests execution, sometimes a previous test
          # may have changed the filter, which makes the below action needed.
          # TODO: Make this test completely independent, not requiring the below step.
          show.select_all_activities_filter
          # We add a space together with the '/promote' string to avoid test flakiness
          # due to the tooltip '/promote Promote issue to an epic (may expose
          # confidential information)' from being shown, which may cause the click not
          # to work properly.
          show.comment('/promote ')
        end

        project.group.visit!
        Page::Group::Menu.perform(&:click_group_epics_link)
        QA::EE::Page::Group::Epic::Index.perform do |index|
          expect(index).to have_epic_title(issue.title)
        end
      end
    end
  end
end
