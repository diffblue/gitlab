# frozen_string_literal: true

module EE
  module DependencyProxy
    module GroupAccess
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      private

      override :authorize_read_dependency_proxy!
      def authorize_read_dependency_proxy!
        if ip_restricted?(group)
          ::Gitlab::AuthLogger.warn(
            class: self.class.name,
            message: 'IP restriction violation',
            authenticated_subject_id: auth_user&.id,
            authenticated_subject_type: auth_user&.class&.name,
            authenticated_subject_username: auth_user&.username,
            group_id: group&.id,
            group_path: group&.full_path,
            ip: ::Gitlab::IpAddressState.current
          )
        end

        super
      end

      def ip_restricted?(group)
        !::Gitlab::IpRestriction::Enforcer.new(group).allows_current_ip?
      end
    end
  end
end
