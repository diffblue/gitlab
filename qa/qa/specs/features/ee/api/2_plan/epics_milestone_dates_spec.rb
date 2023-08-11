# frozen_string_literal: true

require 'airborne'

module QA
  RSpec.describe 'Plan', product_group: :product_planning do
    # TODO: Convert back to reliable once proved to be stable. Related issue: https://gitlab.com/gitlab-org/gitlab/-/issues/219495
    describe 'Epics milestone dates API' do
      let(:milestone_start_date) { (Date.today + 100).iso8601 }
      let(:milestone_due_date) { (Date.today + 120).iso8601 }
      let(:fixed_start_date) { Date.today.iso8601 }
      let(:fixed_due_date) { (Date.today + 90).iso8601 }
      let(:api_client) { Runtime::API::Client.new(:gitlab) }
      let(:group) { create(:group, path: "epic-milestone-group-#{SecureRandom.hex(8)}") }
      let(:project) { create(:project, name: "epic-milestone-project-#{SecureRandom.hex(8)}", group: group) }

      it 'updates epic dates when updating milestones', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347958' do
        epic, milestone = create_epic_issue_milestone
        new_milestone_start_date = (Date.today + 20).iso8601
        new_milestone_due_date = (Date.today + 30).iso8601

        # Update Milestone to different dates and see it reflecting in the epics
        request = create_request("/projects/#{project.id}/milestones/#{milestone.id}")
        put request.url, start_date: new_milestone_start_date, due_date: new_milestone_due_date
        expect_status(200)

        epic.reload!

        expect(epic.start_date_from_milestones).to eq(new_milestone_start_date)
        expect(epic.due_date_from_milestones).to eq(new_milestone_due_date)
        expect(epic.start_date).to eq(new_milestone_start_date)
        expect(epic.due_date).to eq(new_milestone_due_date)
      end

      it 'updates epic dates when adding another issue', :reliable, testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347955' do
        epic = create_epic_issue_milestone[0]
        new_milestone_start_date = Date.today.iso8601
        new_milestone_due_date = (Date.today + 150).iso8601

        # Add another Issue and milestone
        second_milestone = create_milestone(new_milestone_start_date, new_milestone_due_date)
        second_issue = create_issue(second_milestone)
        add_issue_to_epic(epic, second_issue)

        epic.reload!

        expect(epic.start_date_from_milestones).to eq(new_milestone_start_date)
        expect(epic.due_date_from_milestones).to eq(new_milestone_due_date)
        expect(epic.start_date).to eq(new_milestone_start_date)
        expect(epic.due_date).to eq(new_milestone_due_date)
      end

      it 'updates epic dates when removing issue', :reliable, testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347957' do
        epic = create_epic_issue_milestone[0]

        # Get epic_issue_id
        request = create_request("/groups/#{group.id}/epics/#{epic.iid}/issues")
        get request.url
        expect_status(200)
        epic_issue_id = json_body[0][:epic_issue_id]

        # Remove Issue
        request = create_request("/groups/#{group.id}/epics/#{epic.iid}/issues/#{epic_issue_id}")
        delete request.url
        expect_status(200)

        epic.reload!

        expect(epic.start_date_from_milestones).to be_nil
        expect(epic.due_date_from_milestones).to be_nil
        expect(epic.start_date).to be_nil
        expect(epic.due_date).to be_nil
      end

      it 'updates epic dates when deleting milestones', :reliable, testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347956' do
        epic, milestone = create_epic_issue_milestone

        milestone.remove_via_api!
        epic.reload!

        expect(epic.start_date_from_milestones).to be_nil
        expect(epic.due_date_from_milestones).to be_nil
        expect(epic.start_date).to be_nil
        expect(epic.due_date).to be_nil
      end

      private

      def create_epic_issue_milestone
        epic = create_epic
        milestone = create_milestone(milestone_start_date, milestone_due_date)
        issue = create_issue(milestone)
        add_issue_to_epic(epic, issue)
        use_epics_milestone_dates(epic)
        [epic, milestone]
      end

      def create_request(api_endpoint)
        Runtime::API::Request.new(api_client, api_endpoint)
      end

      def create_issue(milestone)
        create(:issue, title: 'My Test Issue', project: project, milestone: milestone)
      end

      def create_milestone(start_date, due_date)
        create(:project_milestone, project: project, start_date: start_date, due_date: due_date)
      end

      def create_epic
        EE::Resource::Epic.fabricate_via_api! do |epic|
          epic.group = group
          epic.title = 'My New Epic'
          epic.due_date_fixed = fixed_due_date
          epic.start_date_fixed = fixed_start_date
          epic.start_date_is_fixed = true
          epic.due_date_is_fixed = true
        end
      end

      def add_issue_to_epic(epic, issue)
        # Add Issue with milestone to an epic
        request = create_request("/groups/#{group.id}/epics/#{epic.iid}/issues/#{issue.id}")
        post request.url

        expect_status(201)
        expect_json('epic.title', 'My New Epic*')
        expect_json('issue.title', 'My Test Issue')
      end

      def use_epics_milestone_dates(epic)
        # Update Epic to use Milestone Dates
        request = create_request("/groups/#{group.id}/epics/#{epic.iid}")
        put request.url, start_date_is_fixed: false, due_date_is_fixed: false
        expect_status(200)

        epic.reload!

        expect(epic.start_date_from_milestones).to eq(milestone_start_date)
        expect(epic.due_date_from_milestones).to eq(milestone_due_date)
        expect(epic.start_date_fixed).to eq(fixed_start_date)
        expect(epic.due_date_fixed).to eq(fixed_due_date)
        expect(epic.start_date).to eq(milestone_start_date)
        expect(epic.due_date).to eq(milestone_due_date)
      end
    end
  end
end
