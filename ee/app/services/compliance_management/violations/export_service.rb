# frozen_string_literal: true

module ComplianceManagement
  module Violations
    class ExportService
      include Gitlab::Routing.url_helpers

      BATCH_SIZE = 25
      TARGET_FILESIZE = 15.megabytes

      def initialize(user:, namespace:, filters: {}, sort: 'SEVERITY_LEVEL_DESC')
        @user = user
        @namespace = namespace
        @filters = filters.to_h
        @sort = sort
      end

      def execute
        return ServiceResponse.error(message: 'namespace must be a group') unless namespace.is_a?(Group)
        return ServiceResponse.error(message: "Access to group denied for user with ID: #{user.id}") unless allowed?

        ServiceResponse.success(payload: csv_builder.render(TARGET_FILESIZE))
      end

      def email_export
        ViolationExportMailerWorker.perform_async(user.id, namespace.id, filters, sort) if feature_enabled?

        ServiceResponse.success
      end

      private

      attr_reader :user, :namespace, :filters, :sort

      def feature_enabled?
        Feature.enabled?(:compliance_violation_csv_export, namespace)
      end

      def allowed?
        Ability.allowed?(user, :read_group_compliance_dashboard, namespace)
      end

      def csv_builder
        @csv_builder ||= CsvBuilder.new(rows, csv_header)
      end

      def rows
        scope = ::MergeRequests::ComplianceViolation.unscoped

        opts = {
          in_operator_optimization_options: {
            array_scope: namespace.all_projects.select(:id),
            array_mapping_scope: ::MergeRequests::ComplianceViolation.method(:in_optimization_array_mapping_scope)
          }
        }

        ids = []
        Gitlab::Pagination::Keyset::Iterator.new(scope: scope, **opts).each_batch(of: BATCH_SIZE) do |records|
          ids << records.map(&:id)
        end

        ::MergeRequests::ComplianceViolation.where(id: ids.flatten) # rubocop: disable CodeReuse/ActiveRecord
      end

      def csv_header
        {
          'Title' => 'title',
          'Severity' => 'severity_level',
          'Violation' => 'reason',
          'Merge request' => ->(violation) { project_merge_request_url violation.project, violation.merge_request },
          'Change made by User ID' => 'violating_user_id',
          'Date merged' => 'merged_at'
        }
      end
    end
  end
end
