# frozen_string_literal: true

module ComplianceManagement
  class ViolationExportMailerWorker
    ExportFailedError = Class.new StandardError

    include ApplicationWorker

    version 1
    feature_category :compliance_management
    deduplicate :until_executed, including_scheduled: true
    data_consistency :delayed
    urgency :low
    idempotent!

    def perform(user_id, namespace_id, filters = {}, sort = 'SEVERITY_LEVEL_DESC')
      @user = User.find user_id
      @namespace = Namespace.find namespace_id
      @filters = filters
      @sort = sort

      return unless feature_enabled?

      raise ExportFailedError, 'An error occurred generating the violation export' unless csv_export&.success?

      Notify.compliance_violations_csv_email(
        user: @user,
        group: @namespace,
        attachment: csv_export.payload,
        filename: filename
      ).deliver_now
    rescue ActiveRecord::RecordNotFound => e
      Gitlab::ErrorTracking.log_exception(e)
    end

    private

    def feature_enabled?
      Feature.enabled?(:compliance_violation_csv_export, @namespace)
    end

    def csv_export
      @csv_export ||= ComplianceManagement::Violations::ExportService.new(
        user: @user,
        namespace: @namespace,
        filters: @filters,
        sort: @sort
      ).execute
    end

    def filename
      "#{Date.current.iso8601}-compliance_violations_export-#{@namespace.id}.csv"
    end
  end
end
