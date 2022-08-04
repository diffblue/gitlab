# frozen_string_literal: true

module Analytics
  class MergeRequestMetricsCalculator
    def initialize(merge_request)
      @merge_request = merge_request
    end

    def productivity_data
      {
        first_comment_at: first_comment_at,
        first_commit_at: first_commit_at,
        last_commit_at: last_commit_at,
        commits_count: commits_count,
        diff_size: diff_size,
        modified_paths_size: modified_paths_size
      }
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def line_counts_data
      {
        added_lines: raw_diff_files.sum(&:added_lines),
        removed_lines: raw_diff_files.sum(&:removed_lines)
      }
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def first_comment_at
      merge_request.related_notes.by_humans
        .where.not(author_id: merge_request.author_id)
        .fresh.first&.created_at
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def first_approved_at
      merge_request.approvals.order(id: :asc).pick(:created_at)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def first_reassigned_at
      merge_request.merge_request_assignees
        .where.not(assignee: merge_request.author)
        .order(id: :asc)
        .pick(:created_at)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    attr_reader :merge_request

    delegate :commits_count, :merge_request_diff, to: :merge_request

    def diff_size
      merge_request_diff.lines_count
    end

    def first_commit_at
      merge_request_diff&.first_commit&.authored_date
    end

    def last_commit_at
      merge_request_diff&.last_commit&.committed_date
    end

    def modified_paths_size
      merge_request.modified_paths.size
    end

    def raw_diff_files
      @raw_diff_files ||= merge_request_diff.diffs.raw_diff_files
    end
  end
end
