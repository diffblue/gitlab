# frozen_string_literal: true

module Abuse
  class NewAbuseReportWorker
    include ApplicationWorker

    feature_category :instance_resiliency

    data_consistency :delayed
    urgency :low

    idempotent!

    attr_reader :user, :reporter

    def perform(abuse_report_id)
      abuse_report = AbuseReport.find_by_id(abuse_report_id)
      return unless abuse_report&.category == 'spam'

      @reporter = abuse_report.reporter
      @user = abuse_report.user

      return unless user && reporter
      return unless reporter.gitlab_employee?
      return unless bannable_user?

      ApplicationRecord.transaction do
        UserCustomAttribute.set_banned_by_abuse_report(abuse_report) if user.ban!
      end

      log_event
    end

    private

    def bannable_user?
      return false unless user.active? && user.human?
      return false if user.gitlab_employee? || user.account_age_in_days > 7
      return false if user.namespace.paid? || user_owns_populated_namespaces?

      true
    end

    def user_owns_populated_namespaces?
      user.owned_groups.find { |group| group.users_count > 5 }
    end

    def log_event
      Gitlab::AppLogger.info(
        message: "User ban",
        user: user.username.to_s,
        email: user.email.to_s,
        ban_by: reporter.username.to_s,
        reason: 'abuse report'
      )
    end
  end
end
