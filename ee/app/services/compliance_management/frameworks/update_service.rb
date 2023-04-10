# frozen_string_literal: true

module ComplianceManagement
  module Frameworks
    class UpdateService < BaseService
      include ::ComplianceManagement::Frameworks

      attr_reader :framework, :current_user, :params

      def initialize(framework:, current_user:, params:)
        @framework = framework
        @current_user = current_user
        @params = params
      end

      def execute
        return error unless permitted?

        unless compliance_pipeline_configuration_available?
          framework.errors.add(:pipeline_configuration_full_path, 'feature is not available')
          return error
        end

        return error unless framework.update(params.except(:default))

        after_execute
        success
      end

      def success
        ServiceResponse.success(payload: { framework: framework })
      end

      def error
        ServiceResponse.error(message: _('Failed to update framework'), payload: framework.errors)
      end

      private

      def audit_changes
        framework.previous_changes.each do |attribute, changes|
          next if attribute.eql?('updated_at')

          audit_context = {
            name: 'update_compliance_framework',
            author: current_user,
            scope: framework.namespace,
            target: framework,
            message: "Changed compliance framework's #{attribute} from #{changes[0]} to #{changes[1]}"
          }

          ::Gitlab::Audit::Auditor.audit(audit_context)
        end
      end

      def permitted?
        can? current_user, :manage_compliance_framework, framework
      end

      def update_default_framework
        return if params[:default].nil?

        # do not update if the current framework default matches `params[:default]`
        is_framework_default = framework.id == framework.namespace.namespace_settings.default_compliance_framework_id
        return if is_framework_default == params[:default]

        default_framework_id = params[:default] ? framework.id : nil

        ::Groups::UpdateService.new(
          framework.namespace,
          current_user,
          default_compliance_framework_id: default_framework_id
        ).execute
      end

      def after_execute
        audit_changes
        update_default_framework
      end
    end
  end
end
