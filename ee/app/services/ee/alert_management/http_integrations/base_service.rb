# frozen_string_literal: true

module EE
  module AlertManagement
    module HttpIntegrations
      module BaseService
        extend ::Gitlab::Utils::Override

        private

        override :too_many_integrations?
        def too_many_integrations?(_id)
          return false if project.licensed_feature_available?(:multiple_alert_http_integrations)

          super
        end

        override :permitted_params_keys
        def permitted_params_keys
          return super unless ::Gitlab::AlertManagement.custom_mapping_available?(project)

          super + %i[payload_example payload_attribute_mapping]
        end
      end
    end
  end
end
