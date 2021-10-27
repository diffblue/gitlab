# frozen_string_literal: true

module Security
  module Orchestration
    class UnassignService < ::BaseService
      def execute
        return error(_('Policy project doesn\'t exist')) unless security_orchestration_policy_configuration

        result = security_orchestration_policy_configuration.delete
        return success if result

        error(project.security_orchestration_policy_configuration.errors.full_messages.to_sentence)
      end

      private

      delegate :security_orchestration_policy_configuration, to: :project

      def success
        ServiceResponse.success
      end

      def error(message)
        ServiceResponse.error(message: message)
      end
    end
  end
end
