# frozen_string_literal: true

module Groups
  class ComplianceReportCsvService
    TARGET_FILESIZE = 15.megabytes

    def initialize(current_user, group, filter_params = {})
      raise ArgumentError, 'The group is a required argument' if group.blank?
      raise ArgumentError, 'The user is a required argument' if current_user.blank?

      @current_user = current_user
      @group = group
      @filter_params = filter_params
    end

    def csv_data
      ServiceResponse.success(payload: csv_builder.render(TARGET_FILESIZE))
    end

    def enqueue_worker
      ComplianceManagement::ChainOfCustodyReportWorker.perform_async(
        user_id: current_user.id,
        group_id: group.id,
        commit_sha: filter_params[:commit_sha]
      )

      ServiceResponse.success
    end

    private

    attr_reader :current_user, :group, :filter_params

    def csv_builder
      @csv_builder ||= CsvBuilder.new(data, csv_headers)
    end

    def data
      ::ComplianceManagement::ComplianceReport::CommitLoader.new(
        group,
        current_user,
        filter_params
      )
    end

    def csv_headers
      {
        'Commit Sha' => 'sha',
        'Commit Author' => 'author',
        'Committed By' => 'committer',
        'Date Committed' => 'committed_at',
        'Group' => 'group',
        'Project' => 'project',
        'Merge Commit' => 'merge_commit',
        'Merge Request' => 'merge_request_id',
        'Merged By' => 'merged_by',
        'Merged At' => 'merged_at',
        'Pipeline' => 'pipeline',
        'Approver(s)' => 'approvers'
      }
    end
  end
end
