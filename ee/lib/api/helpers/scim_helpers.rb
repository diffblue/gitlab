# frozen_string_literal: true

module API
  module Helpers
    module ScimHelpers
      def scim_not_found!(message:)
        render_scim_error(::EE::API::Entities::Scim::NotFound, message)
      end

      def scim_error!(message:)
        render_scim_error(::EE::API::Entities::Scim::Error, message)
      end

      def scim_conflict!(message:)
        render_scim_error(::EE::API::Entities::Scim::Conflict, message)
      end

      def render_scim_error(error_class, message)
        error!({ with: error_class }.merge(detail: message), error_class::STATUS)
      end

      def sanitize_request_parameters(parameters)
        filter = ActiveSupport::ParameterFilter.new(::Rails.application.config.filter_parameters)
        filter.filter(parameters)
      end

      def update_scim_user(identity)
        parser = ::EE::Gitlab::Scim::ParamsParser.new(params)
        parsed_hash = parser.update_params

        if parser.deprovision_user?
          patch_deprovision(identity)
        elsif reprovisionable?(identity) && parser.reprovision_user?
          reprovision(identity)
        elsif parsed_hash[:extern_uid]
          identity.update(parsed_hash.slice(:extern_uid))
        else
          # With 15.0, we no longer allow modifying user attributes.
          # However, we mark the operation as successful to avoid breaking
          # existing automations
          true
        end
      end

      def reprovisionable?(identity)
        return true if identity.respond_to?(:active) && !identity.active?

        false
      end
    end
  end
end
