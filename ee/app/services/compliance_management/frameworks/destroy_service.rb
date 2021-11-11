# frozen_string_literal: true

module ComplianceManagement
  module Frameworks
    class DestroyService < BaseService
      attr_reader :framework, :current_user

      def initialize(framework:, current_user:)
        @framework = framework
        @current_user = current_user
      end

      def execute
        return ServiceResponse.error(message: _('Not permitted to destroy framework')) unless permitted?

        framework.destroy ? success : error
      end

      private

      def permitted?
        can? current_user, :manage_compliance_framework, framework
      end

      def success
        audit_destroy
        ServiceResponse.success(message: _('Framework successfully deleted'))
      end

      def error
        ServiceResponse.error(message: _('Failed to create framework'), payload: framework.errors )
      end

      def audit_destroy
        audit_context = {
          name: 'destroy_compliance_framework',
          author: current_user,
          scope: framework.namespace,
          target: framework,
          message: "Destroyed compliance framework #{framework.name}"
        }

        ::Gitlab::Audit::Auditor.audit(audit_context)
      end
    end
  end
end
