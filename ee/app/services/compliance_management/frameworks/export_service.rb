# frozen_string_literal: true

module ComplianceManagement
  module Frameworks
    class ExportService
      TARGET_FILESIZE = 15.megabytes

      def initialize(user:, namespace:)
        @user = user
        @namespace = namespace
      end

      def execute
        return ServiceResponse.error(message: 'namespace must be a group') unless namespace.is_a?(Group)

        ServiceResponse.success payload: csv_builder.render(TARGET_FILESIZE)
      end

      def email_export
        FrameworkExportMailerWorker.perform_async user.id, namespace.id

        ServiceResponse.success
      end

      private

      attr_reader :user, :namespace

      def csv_builder
        @csv_builder ||= CsvBuilder.new data, csv_header
      end

      def data
        GroupProjectsFinder.new(
          group: namespace,
          current_user: user,
          options: finder_params
        ).execute
      end

      def finder_params
        { include_subgroups: true }
      end

      def csv_header
        {
          'Project' => 'name',
          'Project Path' => 'full_path',
          'Framework' => ->(project) { project.compliance_management_framework&.name },
          'isDefaultFramework' => ->(project) {
            return unless project.compliance_management_framework

            project.compliance_management_framework.id == project.root_ancestor.default_compliance_framework_id
          }
        }
      end
    end
  end
end
