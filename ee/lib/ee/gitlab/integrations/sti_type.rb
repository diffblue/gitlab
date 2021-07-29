# frozen_string_literal: true

module EE
  module Gitlab
    module Integrations
      module StiType
        extend ActiveSupport::Concern

        EE_NAMESPACED_INTEGRATIONS = (::Gitlab::Integrations::StiType::NAMESPACED_INTEGRATIONS + %w(
          Github GitlabSlackApplication
        )).freeze

        class_methods do
          extend ::Gitlab::Utils::Override

          override :namespaced_integrations
          def namespaced_integrations
            EE_NAMESPACED_INTEGRATIONS
          end
        end
      end
    end
  end
end
