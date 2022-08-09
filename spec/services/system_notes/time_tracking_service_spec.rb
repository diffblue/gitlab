# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::SystemNotes::TimeTrackingService do
  let_it_be(:author)   { create(:user) }
  let_it_be(:project)  { create(:project, :repository) }

  describe '#change_start_date_or_due_date' do
    subject(:note) { described_class.new(noteable: noteable, project: project, author: author).change_start_date_or_due_date(changed_dates) }

    let(:start_date) { Date.today }
    let(:due_date) { 1.week.from_now.to_date }
    let(:changed_dates) { { 'due_date' => [nil, due_date], 'start_date' => [nil, start_date] } }

    let_it_be(:noteable) { create(:issue, project: project) }

    context 'when noteable is an issue' do
      it_behaves_like 'a note with overridable created_at'

      it_behaves_like 'a system note' do
        let(:action) { 'start_date_or_due_date' }
      end

      context 'when both dates are added' do
        it 'sets the correct note message' do
          expect(note.note).to eq("changed start date to #{start_date.to_s(:long)} and changed due date to #{due_date.to_s(:long)}")
        end
      end

      context 'when both dates are removed' do
        let(:changed_dates) { { 'due_date' => [due_date, nil], 'start_date' => [start_date, nil] } }

        before do
          noteable.update!(start_date: start_date, due_date: due_date)
        end

        it 'sets the correct note message' do
          expect(note.note).to eq('removed start date and removed due date')
        end
      end

      context 'when due date is added' do
        let(:changed_dates) { { 'due_date' => [nil, due_date] } }

        it 'tracks the issue event in usage ping' do
          expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).to receive(:track_issue_due_date_changed_action).with(author: author)

          subject
        end

        it 'sets the correct note message' do
          expect(note.note).to eq("changed due date to #{due_date.to_s(:long)}")
        end

        context 'and start date removed' do
          let(:changed_dates) { { 'due_date' => [nil, due_date], 'start_date' => [start_date, nil] } }

          it 'sets the correct note message' do
            expect(note.note).to eq("removed start date and changed due date to #{due_date.to_s(:long)}")
          end
        end
      end

      context 'when start_date is added' do
        let(:changed_dates) { { 'start_date' => [nil, start_date] } }

        it 'does not track the issue event in usage ping' do
          expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).not_to receive(:track_issue_due_date_changed_action)

          subject
        end

        it 'sets the correct note message' do
          expect(note.note).to eq("changed start date to #{start_date.to_s(:long)}")
        end

        context 'and due date removed' do
          let(:changed_dates) { { 'due_date' => [due_date, nil], 'start_date' => [nil, start_date] } }

          it 'sets the correct note message' do
            expect(note.note).to eq("changed start date to #{start_date.to_s(:long)} and removed due date")
          end
        end
      end

      context 'when no dates are changed' do
        let(:changed_dates) { {} }

        it 'does not create a note and returns nil' do
          expect do
            note
          end.to not_change(Note, :count)

          expect(note).to be_nil
        end
      end
    end

    context 'when noteable is a merge request' do
      let_it_be(:noteable) { create(:merge_request, source_project: project) }

      it 'does not track the issue event in usage ping' do
        expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).not_to receive(:track_issue_due_date_changed_action)

        subject
      end
    end
  end

  describe '#change_time_estimate' do
    subject { described_class.new(noteable: noteable, project: project, author: author).change_time_estimate }

    context 'when noteable is an issue' do
      let_it_be(:noteable, reload: true) { create(:issue, project: project) }

      it_behaves_like 'a system note' do
        let(:action) { 'time_tracking' }
      end

      context 'with a time estimate' do
        it 'sets the note text' do
          noteable.update_attribute(:time_estimate, 277200)

          expect(subject.note).to eq "changed time estimate to 1w 4d 5h"
        end

        context 'when time_tracking_limit_to_hours setting is true' do
          before do
            stub_application_setting(time_tracking_limit_to_hours: true)
          end

          it 'sets the note text' do
            noteable.update_attribute(:time_estimate, 277200)

            expect(subject.note).to eq "changed time estimate to 77h"
          end
        end
      end

      context 'without a time estimate' do
        it 'sets the note text' do
          expect(subject.note).to eq "removed time estimate"
        end
      end

      it 'tracks the issue event in usage ping' do
        expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).to receive(:track_issue_time_estimate_changed_action).with(author: author)

        subject
      end
    end

    context 'when noteable is a merge request' do
      let_it_be(:noteable) { create(:merge_request, source_project: project) }

      it 'does not track the issue event in usage ping' do
        expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).not_to receive(:track_issue_time_estimate_changed_action).with(author: author)

        subject
      end
    end
  end

  describe '#create_timelog' do
    subject { described_class.new(noteable: noteable, project: project, author: author).created_timelog(timelog) }

    context 'when the timelog has a positive time spent value' do
      let_it_be(:noteable, reload: true) { create(:issue, project: project) }

      let(:timelog) { create(:timelog, user: author, issue: noteable, time_spent: 1800, spent_at: '2022-03-30T00:00:00.000Z') }

      it 'sets the note text' do
        expect(subject.note).to eq "added 30m of time spent at 2022-03-30"
      end
    end

    context 'when the timelog has a negative time spent value' do
      let_it_be(:noteable, reload: true) { create(:issue, project: project) }

      let(:timelog) { create(:timelog, user: author, issue: noteable, time_spent: -1800, spent_at: '2022-03-30T00:00:00.000Z') }

      it 'sets the note text' do
        expect(subject.note).to eq "subtracted 30m of time spent at 2022-03-30"
      end
    end
  end

  describe '#remove_timelog' do
    subject { described_class.new(noteable: noteable, project: project, author: author).remove_timelog(timelog) }

    context 'when the timelog has a positive time spent value' do
      let_it_be(:noteable, reload: true) { create(:issue, project: project) }

      let(:timelog) { create(:timelog, user: author, issue: noteable, time_spent: 1800, spent_at: '2022-03-30T00:00:00.000Z') }

      it 'sets the note text' do
        expect(subject.note).to eq "deleted 30m of spent time from 2022-03-30"
      end
    end

    context 'when the timelog has a negative time spent value' do
      let_it_be(:noteable, reload: true) { create(:issue, project: project) }

      let(:timelog) { create(:timelog, user: author, issue: noteable, time_spent: -1800, spent_at: '2022-03-30T00:00:00.000Z') }

      it 'sets the note text' do
        expect(subject.note).to eq "deleted -30m of spent time from 2022-03-30"
      end
    end
  end

  describe '#change_time_spent' do
    subject { described_class.new(noteable: noteable, project: project, author: author).change_time_spent }

    context 'when noteable is an issue' do
      let_it_be(:noteable, reload: true) { create(:issue, project: project) }

      it_behaves_like 'a system note' do
        let(:action) { 'time_tracking' }

        before do
          spend_time!(277200)
        end
      end

      context 'when time was added' do
        it 'sets the note text' do
          spend_time!(277200)

          expect(subject.note).to eq "added 1w 4d 5h of time spent"
        end

        context 'when time was subtracted' do
          it 'sets the note text' do
            spend_time!(360000)
            spend_time!(-277200)

            expect(subject.note).to eq "subtracted 1w 4d 5h of time spent"
          end
        end

        context 'when time was removed' do
          it 'sets the note text' do
            spend_time!(:reset)

            expect(subject.note).to eq "removed time spent"
          end
        end

        context 'when time_tracking_limit_to_hours setting is true' do
          before do
            stub_application_setting(time_tracking_limit_to_hours: true)
          end

          it 'sets the note text' do
            spend_time!(277200)

            expect(subject.note).to eq "added 77h of time spent"
          end
        end

        it 'tracks the issue event in usage ping' do
          expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).to receive(:track_issue_time_spent_changed_action).with(author: author)

          spend_time!(277200)

          subject
        end
      end

      context 'when noteable is a merge request' do
        let_it_be(:noteable) { create(:merge_request, source_project: project) }

        it 'does not track the issue event in usage ping' do
          expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).not_to receive(:track_issue_time_estimate_changed_action).with(author: author)

          spend_time!(277200)

          subject
        end
      end

      def spend_time!(seconds)
        noteable.spend_time(duration: seconds, user_id: author.id)
        noteable.save!
      end
    end
  end
end
