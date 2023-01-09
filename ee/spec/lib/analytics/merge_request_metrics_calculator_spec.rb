# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::MergeRequestMetricsCalculator, feature_category: :code_review_workflow do
  subject { described_class.new(merge_request) }

  let_it_be(:merge_request) { create(:merge_request, :merged, created_at: 31.days.ago) }
  let_it_be(:merge_request_note) do
    create(:diff_note_on_merge_request, noteable: merge_request, project: merge_request.source_project, author: create(:user))
  end

  let_it_be(:merge_request_author_note) do
    create(:diff_note_on_merge_request,
           noteable: merge_request,
           project: merge_request.source_project,
           author: merge_request.author,
           created_at: 11.months.ago
          )
  end

  let_it_be(:merge_request_bot_note) do
    create(:diff_note_on_merge_request,
           noteable: merge_request,
           project: merge_request.source_project,
           author: create(:user, :bot),
           created_at: 12.months.ago
          )
  end

  describe '#productivity_data' do
    it 'calculates productivity data' do
      expected_data = {
        first_comment_at: be_like_time(merge_request_note.created_at),
        first_commit_at: be_like_time(merge_request.first_commit.authored_date),
        last_commit_at: be_like_time(merge_request.merge_request_diff.last_commit.committed_date),
        commits_count: merge_request.commits_count,
        diff_size: merge_request.merge_request_diff.lines_count,
        modified_paths_size: merge_request.modified_paths.size
      }

      expect(subject.productivity_data).to match(expected_data)
    end
  end

  describe '#first_comment_at' do
    it 'returns first non-author comment' do
      expect(subject.first_comment_at).to be_like_time(merge_request_note.created_at)
    end
  end

  describe '#first_approved_at' do
    it 'returns first approval creation timestamp' do
      create :approval, merge_request: merge_request, created_at: 1.day.ago
      create :approval, merge_request: merge_request, created_at: 1.minute.ago

      expect(subject.first_approved_at).to be_like_time(1.day.ago)
    end
  end

  describe '#first_reassigned_at' do
    it 'returns earliest non-author assignee creation timestamp' do
      merge_request.merge_request_assignees.create!(assignee: merge_request.author, created_at: 5.days.ago)
      merge_request.merge_request_assignees.create!(assignee: create(:user), created_at: 3.days.ago)
      merge_request.merge_request_assignees.create!(assignee: create(:user), created_at: 1.day.ago)

      expect(subject.first_reassigned_at).to be_like_time(3.days.ago)
    end
  end
end
