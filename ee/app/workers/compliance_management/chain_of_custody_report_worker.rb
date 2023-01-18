# frozen_string_literal: true

module ComplianceManagement
  class ChainOfCustodyReportWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    version 1

    feature_category :compliance_management
    deduplicate :until_executed, including_scheduled: true
    data_consistency :always
    urgency :low

    def perform(options = {})
      options.symbolize_keys!

      @user = User.find(options[:user_id])
      @group = Group.find(options[:group_id])
      @filter_params = { commit_sha: options[:commit_sha] }.compact

      response = csv_response

      raise 'An error occurred generating the chain of custody report' unless response&.success?

      Notify.merge_commits_csv_email(
        @user,
        @group,
        response.payload,
        merge_commits_csv_filename
      ).deliver_now

    rescue ActiveRecord::RecordNotFound => e
      Gitlab::ErrorTracking.log_exception(e)
    end

    private

    def csv_response
      # currently the commit sha filter still uses the original code
      # path, once that is migrated to
      # Groups::ComplianceReportCsvService the below
      # @filter_params.blank? can be removed
      if Feature.enabled?(:all_commits_compliance_report, @group) && @filter_params.blank?
        Groups::ComplianceReportCsvService.new(
          @user, @group, @filter_params
        ).csv_data
      else
        ::MergeCommits::ExportCsvService.new(@user, @group, @filter_params).csv_data
      end
    end

    def merge_commits_csv_filename
      if Feature.enabled?(:all_commits_compliance_report, @group)
        "#{@group.id}-commits-#{Time.current.to_i}.csv"
      else
        "#{@group.id}-merge-commits-#{Time.current.to_i}.csv"
      end
    end
  end
end
