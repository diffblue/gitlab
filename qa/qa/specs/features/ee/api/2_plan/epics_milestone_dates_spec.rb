# frozen_string_literal: true

require 'airborne'

module QA
  RSpec.describe 'Plan' do
    # TODO: Convert back to reliable once proved to be stable. Related issue: https://gitlab.com/gitlab-org/gitlab/-/issues/219495
    describe 'Epics milestone dates API' do
      before(:context) do
        @api_client = Runtime::API::Client.new(:gitlab)
        @group_id = Resource::Group.fabricate_via_api!.id
        @project_id = create_project
        @milestone_start_date = (Date.today.to_date + 100).strftime("%Y-%m-%d")
        @milestone_due_date = (Date.today.to_date + 120).strftime("%Y-%m-%d")
        @fixed_start_date = Date.today.to_date.strftime("%Y-%m-%d")
        @fixed_due_date = (Date.today.to_date + 90).strftime("%Y-%m-%d")
      end

      it 'changes epic dates when updating milestones', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/quality/test_cases/1480' do
        epic_iid, milestone_id = create_epic_issue_milestone
        milestone_start_date = Date.today.to_date.strftime("%Y-%m-%d")
        milestone_due_date = (Date.today.to_date + 30).strftime("%Y-%m-%d")

        # Update Milestone to different dates and see it reflecting in the epics
        request = create_request("/projects/#{@project_id}/milestones/#{milestone_id}")
        put request.url, start_date: milestone_start_date, due_date: milestone_due_date
        expect_status(200)

        # Get Epic Details
        request = create_request("/groups/#{@group_id}/epics/#{epic_iid}")
        get request.url
        expect_status(200)

        expect_json('start_date_from_milestones', milestone_start_date)
        expect_json('due_date_from_milestones', milestone_due_date)
        expect_json('start_date', milestone_start_date)
        expect_json('due_date', milestone_due_date)
      end

      it 'updates epic dates when adding another issue', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/quality/test_cases/1483' do
        epic_iid = create_epic_issue_milestone[0]
        milestone_start_date = Date.today.to_date.strftime("%Y-%m-%d")
        milestone_due_date = (Date.today.to_date + 150).strftime("%Y-%m-%d")

        # Add another Issue and milestone
        second_milestone_id = create_milestone(milestone_start_date, milestone_due_date)
        second_issue_id = create_issue(second_milestone_id)
        request = create_request("/groups/#{@group_id}/epics/#{epic_iid}/issues/#{second_issue_id}")
        post request.url
        expect_status(201)

        # and check milestone dates
        request = create_request("/groups/#{@group_id}/epics/#{epic_iid}")
        get request.url
        expect_status(200)

        expect_json('start_date_from_milestones', milestone_start_date)
        expect_json('due_date_from_milestones', milestone_due_date)
        expect_json('start_date', milestone_start_date)
        expect_json('due_date', milestone_due_date)
      end

      it 'updates epic dates when removing issue', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/quality/test_cases/1481' do
        epic_iid = create_epic_issue_milestone[0]

        # Get epic_issue_id
        request = create_request("/groups/#{@group_id}/epics/#{epic_iid}/issues")
        get request.url
        expect_status(200)
        epic_issue_id = json_body[0][:epic_issue_id]

        # Remove Issue
        request = create_request("/groups/#{@group_id}/epics/#{epic_iid}/issues/#{epic_issue_id}")
        delete request.url
        expect_status(200)

        # and check milestone dates
        request = create_request("/groups/#{@group_id}/epics/#{epic_iid}")
        get request.url
        expect_status(200)

        expect_json('start_date_from_milestones', nil)
        expect_json('due_date_from_milestones', nil)
        expect_json('start_date', nil)
        expect_json('due_date', nil)
      end

      it 'updates epic dates when deleting milestones', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/quality/test_cases/1482' do
        epic_iid, milestone_id = create_epic_issue_milestone

        # Delete Milestone
        request = create_request("/projects/#{@project_id}/milestones/#{milestone_id}")
        delete request.url
        expect_status(204)

        # and check milestone dates
        request = create_request("/groups/#{@group_id}/epics/#{epic_iid}")
        get request.url
        expect_status(200)

        expect_json('start_date_from_milestones', nil)
        expect_json('due_date_from_milestones', nil)
        expect_json('start_date', nil)
        expect_json('due_date', nil)
      end

      private

      def create_epic_issue_milestone
        epic_iid = create_epic
        milestone_id = create_milestone(@milestone_start_date, @milestone_due_date)
        issue_id = create_issue(milestone_id)
        add_issue_to_epic(epic_iid, issue_id)
        use_epics_milestone_dates(epic_iid)
        [epic_iid, milestone_id]
      end

      def create_request(api_endpoint)
        Runtime::API::Request.new(@api_client, api_endpoint)
      end

      def create_project
        project_name = "project_#{SecureRandom.hex(8)}"
        create_project_request = create_request('/projects')
        post create_project_request.url, path: project_name, name: project_name, namespace_id: @group_id
        expect_status(201)
        json_body[:id]
      end

      def create_issue(milestone_id)
        request = create_request("/projects/#{@project_id}/issues")
        post request.url, title: 'My Test Issue', milestone_id: milestone_id
        expect_status(201)
        json_body[:id]
      end

      def create_milestone(start_date, due_date)
        request = create_request("/projects/#{@project_id}/milestones")
        post request.url, title: "Test_Milestone_#{SecureRandom.hex(8)}", due_date: due_date, start_date: start_date
        expect_status(201)
        json_body[:id]
      end

      def create_epic
        request = create_request("/groups/#{@group_id}/epics")
        post request.url, title: 'My New Epic', due_date_fixed: @fixed_due_date, start_date_fixed: @fixed_start_date, start_date_is_fixed: true, due_date_is_fixed: true
        expect_status(201)
        json_body[:iid]
      end

      def add_issue_to_epic(epic_iid, issue_id)
        # Add Issue with milestone to an epic
        request = create_request("/groups/#{@group_id}/epics/#{epic_iid}/issues/#{issue_id}")
        post request.url

        expect_status(201)
        expect_json('epic.title', 'My New Epic*')
        expect_json('issue.title', 'My Test Issue')
      end

      def use_epics_milestone_dates(epic_iid)
        # Update Epic to use Milestone Dates
        request = create_request("/groups/#{@group_id}/epics/#{epic_iid}")
        put request.url, start_date_is_fixed: false, due_date_is_fixed: false

        expect_status(200)
        expect_json('start_date_from_milestones', @milestone_start_date)
        expect_json('due_date_from_milestones', @milestone_due_date)
        expect_json('due_date_fixed', @fixed_due_date)
        expect_json('start_date_fixed', @fixed_start_date)
        expect_json('start_date', @milestone_start_date)
        expect_json('due_date', @milestone_due_date)
      end
    end
  end
end
