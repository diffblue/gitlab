# frozen_string_literal: true

module ComplianceManagement
  class FrameworkExportMailerWorker
    ExportFailedError = Class.new StandardError

    include ApplicationWorker

    version 1
    feature_category :compliance_management
    deduplicate :until_executed, including_scheduled: true
    data_consistency :delayed
    urgency :low
    idempotent!

    def perform(user_id, namespace_id)
      @user = User.find user_id
      @namespace = Namespace.find namespace_id

      raise ExportFailedError, 'An error occurred generating the framework export' unless csv_export&.success?

      Notify.compliance_frameworks_csv_email(
        user: @user,
        group: @namespace,
        attachment: csv_export.payload,
        filename: filename
      ).deliver_now
    rescue ActiveRecord::RecordNotFound => e
      Gitlab::ErrorTracking.log_exception(e)
    end

    private

    def csv_export
      @csv_export ||= ComplianceManagement::Frameworks::ExportService.new(user: @user, namespace: @namespace).execute
    end

    def filename
      "#{Date.current.iso8601}-compliance_framework_export-#{@namespace.id}.csv"
    end
  end
end
