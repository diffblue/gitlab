# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Burndown, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }

  let(:start_date) { "2017-03-01" }
  let(:due_date) { "2017-03-03" }

  shared_examples 'burndown for milestone' do
    before do
      build_sample(milestone, issue_params)
      travel_to(due_date)
    end

    subject { described_class.new(milestone.issues_visible_to_user(user), milestone.start_date, milestone.due_date).as_json }

    it 'generates an array of issues with date, issue weight and action' do
      expect(subject).to match_array(
        [
          { created_at: Date.new(2017, 2, 28).beginning_of_day, weight: 2, action: 'created' },
          { created_at: Date.new(2017, 2, 28).beginning_of_day, weight: 2, action: 'closed' },
          { created_at: Date.new(2017, 3, 1).beginning_of_day,  weight: 2, action: 'created' },
          { created_at: Date.new(2017, 3, 1).beginning_of_day,  weight: 2, action: 'created' },
          { created_at: Date.new(2017, 3, 2).beginning_of_day,  weight: 2, action: 'created' },
          { created_at: Date.new(2017, 3, 2).beginning_of_day,  weight: 2, action: 'closed' },
          { created_at: Date.new(2017, 3, 2).beginning_of_day,  weight: 2, action: 'closed' },
          { created_at: Date.new(2017, 3, 3).beginning_of_day,  weight: 2, action: 'created' },
          { created_at: Date.new(2017, 3, 3).beginning_of_day,  weight: 2, action: 'reopened' }
        ])
    end

    context 'when issues belong to a public project' do
      let_it_be(:non_member) { create(:user) }

      subject do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
        described_class.new(milestone.issues_visible_to_user(non_member), milestone.start_date, milestone.due_date).as_json.each { |event| event[:created_at] = event[:created_at].to_date }
      end

      it 'does not include confidential issues for users who are not project members' do
        expect(subject).to match_array(
          [
            { created_at: Date.new(2017, 2, 28).beginning_of_day, weight: 2, action: 'created' },
            { created_at: Date.new(2017, 2, 28).beginning_of_day, weight: 2, action: 'closed' },
            { created_at: Date.new(2017, 3, 1).beginning_of_day,  weight: 2, action: 'created' },
            { created_at: Date.new(2017, 3, 2).beginning_of_day,  weight: 2, action: 'created' },
            { created_at: Date.new(2017, 3, 2).beginning_of_day,  weight: 2, action: 'closed' },
            { created_at: Date.new(2017, 3, 3).beginning_of_day,  weight: 2, action: 'created' },
            { created_at: Date.new(2017, 3, 3).beginning_of_day,  weight: 2, action: 'reopened' }
          ])
      end
    end

    it "returns empty array if milestone start date is nil" do
      milestone.update!(start_date: nil)

      expect(subject).to eq([])
    end

    it "returns empty array if milestone due date is nil" do
      milestone.update!(due_date: nil)

      expect(subject).to eq([])
    end

    it "counts until today if milestone due date > Date.today" do
      travel_to(milestone.due_date - 1.day)

      expect(subject.max_by { |event| event[:created_at] }[:created_at].to_date).to eq(Date.today)
    end

    it "ignores follow-up events with the same action" do
      create(:event, target: milestone.issues.first, created_at: milestone.start_date + 1.minute, action: :reopened)
      event1 = create(:closed_issue_event, target: milestone.issues.first, created_at: milestone.start_date + 2.minutes)
      event2 = create(:closed_issue_event, target: milestone.issues.first, created_at: milestone.start_date + 3.minutes)

      expect(closed_at_time(subject, event1.created_at).size).to eq(1)
      expect(closed_at_time(subject, event2.created_at).size).to eq(0)
    end

    context "when all closed issues do not have closed events" do
      before do
        Event.where(target: milestone.issues, action: :closed).destroy_all # rubocop: disable Cop/DestroyAll
      end

      it "considers closed_at as milestone start date" do
        expect(subject).to match_array(
          [
            { created_at: Date.new(2017, 2, 28).beginning_of_day, weight: 2, action: 'created' },
            { created_at: Date.new(2017, 3, 1).beginning_of_day,  weight: 2, action: 'created' },
            { created_at: Date.new(2017, 3, 1).beginning_of_day,  weight: 2, action: 'created' },
            { created_at: Date.new(2017, 3, 1).beginning_of_day,  weight: 2, action: 'closed' },
            { created_at: Date.new(2017, 3, 1).beginning_of_day,  weight: 2, action: 'closed' },
            { created_at: Date.new(2017, 3, 2).beginning_of_day,  weight: 2, action: 'created' },
            { created_at: Date.new(2017, 3, 3).beginning_of_day,  weight: 2, action: 'created' },
            { created_at: Date.new(2017, 3, 3).beginning_of_day,  weight: 2, action: 'reopened' }
          ])
      end
    end
  end

  describe 'project milestone burndown' do
    it_behaves_like 'burndown for milestone' do
      let(:milestone) { create(:milestone, start_date: start_date, due_date: due_date) }
      let(:project) { milestone.project }
      let(:issue_params) do
        {
          milestone: milestone,
          weight: 2,
          project_id: project.id,
          author: user
        }
      end

      let(:scope) { project }
    end
  end

  describe 'group milestone burndown' do
    let(:parent_group) { create(:group) }
    let(:group) { create(:group, parent: parent_group) }
    let(:parent_group_project) { create(:project, group: parent_group) }
    let(:group_project) { create(:project, group: group) }
    let(:parent_group_milestone) { create(:milestone, project: nil, group: parent_group, start_date: start_date, due_date: due_date) }
    let(:group_milestone) { create(:milestone, group: group, start_date: start_date, due_date: due_date) }

    context 'when nested group milestone' do
      before do
        parent_group.add_developer(user)
      end

      it_behaves_like 'burndown for milestone' do
        let(:milestone) { group_milestone }
        let(:project) { group_project }
        let(:issue_params) do
          {
            milestone: milestone,
            weight: 2,
            project_id: group_project.id,
            author: user
          }
        end

        let(:scope) { group }
      end
    end

    context 'when non-nested group milestone' do
      it_behaves_like 'burndown for milestone' do
        let(:milestone) { group_milestone }
        let(:project) { group_project }
        let(:issue_params) do
          {
            milestone: milestone,
            weight: 2,
            project_id: group_project.id,
            author: user
          }
        end

        let(:scope) { group }
      end
    end
  end

  describe 'load burndown events' do
    let(:project) { create(:project) }
    let(:milestone) { create(:milestone, project: project, start_date: start_date, due_date: due_date) }

    subject { described_class.new(milestone.issues_visible_to_user(user), milestone.start_date, milestone.due_date).as_json }

    before do
      project.add_developer(user)
    end

    it 'avoids N+1 database queries' do
      travel_to(milestone.due_date) do
        create(:issue, milestone: milestone, weight: 2, project: project, author: user)

        control_count = ActiveRecord::QueryRecorder.new(skip_cached: false) do
          subject
        end.count

        create_list(:issue, 3, milestone: milestone, weight: 2, project: project, author: user)

        expect do
          subject
        end.not_to exceed_all_query_limit(control_count)
      end
    end
  end

  def build_sample(milestone, issue_params)
    project.add_maintainer(user)

    issues = []
    confidential_issues = []

    milestone.start_date.yesterday.upto(milestone.due_date) do |date|
      travel_to(date) do
        # Make sure issues are created at exactly the beginning of the day to
        # facilitate comparison in specs
        issue_params_for_date = issue_params.merge(created_at: date.beginning_of_day)

        # Create one issue each day
        issues << create(:issue, issue_params_for_date)

        if Date.today == milestone.start_date - 1.day
          # Close issue created before milestone start date to make sure issues
          # and events created before the milestone starts are included
          close_issue(issues.first)
        end

        if Date.today == milestone.start_date
          # Create one confidential issue to assist in testing issue visibility.
          confidential_issues << create(:issue, :confidential, issue_params_for_date)
        end

        if Date.today == milestone.start_date + 1.day
          # Close issue created on milestone start date
          close_issue(issues.second)

          # Close confidential issue to assist in testing event visibility.
          close_issue(confidential_issues.first)
        end

        if Date.today == milestone.start_date + 2.days
          # Reopen issue created on milestone start date
          reopen_issue(issues.second)
        end
      end
    end
  end

  def close_issue(issue)
    Issues::CloseService.new(container: issue.project, current_user: user).execute(issue)
    adjust_issue_event_creation_time(issue.events.last)
  end

  def reopen_issue(issue)
    Issues::ReopenService.new(container: issue.project, current_user: user).execute(issue)
    adjust_issue_event_creation_time(issue.events.last)
  end

  # Make sure issue events are created at exactly the beginning of the day to
  # facilitate comparison in specs
  def adjust_issue_event_creation_time(event)
    event.update!(created_at: event.created_at.beginning_of_day)
  end

  def closed_at_time(events, time)
    events.select do |hash|
      hash[:created_at] == time && hash[:action] == 'closed'
    end
  end
end
