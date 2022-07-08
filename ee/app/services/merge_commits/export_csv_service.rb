# frozen_string_literal: true

module MergeCommits
  class ExportCsvService
    include Gitlab::Utils::StrongMemoize
    TARGET_FILESIZE = 15.megabytes

    def initialize(current_user, group, filter_params = {})
      @current_user = current_user
      @group = group
      @filter_params = filter_params
    end

    def csv_data
      ServiceResponse.success(payload: csv_builder.render(TARGET_FILESIZE))
    end

    private

    attr_reader :current_user, :group, :filter_params

    def csv_builder
      @csv_builder ||= CsvBuilder.new(data, header_to_value_hash)
    end

    def data
      strong_memoize(:merge_commits_data) do
        MergeRequestsFinder
          .new(current_user, finder_options)
          .execute
          .preload_author
          .preload_approved_by_users
          .preload_target_project
          .preload_metrics([:merged_by])
      end
    end

    def finder_options
      {
        group_id: group.id,
        state: 'merged',
        merge_commit_sha: filter_params[:commit_sha]
      }
    end

    def header_to_value_hash
      {
        'Merge Commit' => 'merged_commit_sha',
        'Author' => -> (merge_request) { merge_request.author&.name },
        'Merge Request' => 'id',
        'Merged By' => -> (merge_request) { merge_request.metrics&.merged_by&.name },
        'Date Merged' => -> (merge_request) { merge_request.merged_at },
        'Pipeline' => -> (merge_request) { merge_request.metrics&.pipeline_id },
        'Group' => -> (merge_request) { merge_request.project&.namespace&.name },
        'Project' => -> (merge_request) { merge_request.project&.name },
        'Approver(s)' => -> (merge_request) { merge_request.approved_by_users.map(&:name).sort.join(" | ") }
      }
    end
  end
end
