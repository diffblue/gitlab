# frozen_string_literal: true

module EE
  module Auth
    module ContainerRegistryAuthenticationService
      extend ::Gitlab::Utils::Override

      StorageError = Class.new(StandardError)

      override :execute
      def execute(authentication_abilities:)
        super
      rescue StorageError
        error(
          'DENIED',
          status: 403,
          message: 'You are above your storage quota! Visit https://docs.gitlab.com/ee/user/usage_quotas.html to learn more.'
        )
      end

      private

      override :can_access?
      def can_access?(requested_project, requested_action)
        if ::Gitlab.maintenance_mode? && requested_action != 'pull'
          @access_denied_in_maintenance_mode = true # rubocop:disable Gitlab/ModuleWithInstanceVariables
          return false
        end

        raise StorageError if storage_error?(requested_project, requested_action)

        super
      end

      override :extra_info
      def extra_info
        return super unless access_denied_in_maintenance_mode?

        super.merge!({
          message: 'Write access denied in maintenance mode',
          write_access_denied_in_maintenance_mode: true
        })
      end

      # TODO : to remove along with container_registry_legacy_authentication_for_deploy_tokens
      override :deploy_token_can_pull?
      def deploy_token_can_pull?(requested_project)
        return false unless has_authentication_ability?(:read_container_image) && deploy_token.present?

        root_group = requested_project.group&.root_ancestor
        if root_group && ::Feature.enabled?(:container_registry_legacy_authentication_for_deploy_tokens, root_group)
          read_granted = deploy_token.has_access_to?(requested_project) && deploy_token.read_registry?

          log_ip_restriction(requested_project) if read_granted && ip_restricted?(requested_project)

          read_granted
        else
          super
        end
      end

      # TODO : to remove along with container_registry_legacy_authentication_for_deploy_tokens
      override :deploy_token_can_push?
      def deploy_token_can_push?(requested_project)
        return false unless has_authentication_ability?(:create_container_image) && deploy_token.present?

        root_group = requested_project.group&.root_ancestor

        if root_group && ::Feature.enabled?(:container_registry_legacy_authentication_for_deploy_tokens, root_group)
          push_granted = deploy_token.has_access_to?(requested_project) && deploy_token.write_registry?

          log_ip_restriction(requested_project) if push_granted && ip_restricted?(requested_project)

          push_granted
        else
          super
        end
      end

      # TODO : to remove along with container_registry_legacy_authentication_for_deploy_tokens
      def ip_restricted?(requested_project)
        !::Gitlab::IpRestriction::Enforcer.new(requested_project.group).allows_current_ip?
      end

      # TODO : to remove along with container_registry_legacy_authentication_for_deploy_tokens
      def log_ip_restriction(requested_project)
        ::Gitlab::AuthLogger.warn(
          class: self.class.name,
          message: 'IP restriction violation',
          deploy_token_id: deploy_token.id,
          project_id: requested_project&.id,
          project_path: requested_project&.full_path,
          ip: ::Gitlab::IpAddressState.current
        )
      end

      def access_denied_in_maintenance_mode?
        @access_denied_in_maintenance_mode
      end

      def storage_error?(project, action)
        return false unless project
        return false unless action == 'push'

        project.root_ancestor.over_storage_limit?
      end
    end
  end
end
