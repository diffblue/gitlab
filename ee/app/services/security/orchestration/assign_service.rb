# frozen_string_literal: true

module Security
  module Orchestration
    class AssignService < ::BaseContainerService
      def execute
        res = create_or_update_security_policy_configuration

        return success if res

      rescue ActiveRecord::RecordNotFound => _
        error(_('Policy project doesn\'t exist'))
      rescue ActiveRecord::RecordInvalid => _
        error(_('Couldn\'t assign policy to project or group'))
      end

      private

      def create_or_update_security_policy_configuration
        if policy_project_id.blank? && has_existing_policy?
          return unassign_policy_project
        end

        policy_project = Project.find(policy_project_id)

        if has_existing_policy?
          container.security_orchestration_policy_configuration.update!(
            security_policy_management_project_id: policy_project.id
          )
        else
          container.create_security_orchestration_policy_configuration! do |p|
            p.security_policy_management_project_id = policy_project.id
          end
        end
      end

      def unassign_policy_project
        container.security_orchestration_policy_configuration.delete
      end

      def success
        ServiceResponse.success(payload: { policy_project: policy_project_id })
      end

      def error(message)
        ServiceResponse.error(payload: { policy_project: policy_project_id }, message: message)
      end

      def has_existing_policy?
        container.security_orchestration_policy_configuration.present?
      end

      def policy_project_id
        params[:policy_project_id]
      end
    end
  end
end
