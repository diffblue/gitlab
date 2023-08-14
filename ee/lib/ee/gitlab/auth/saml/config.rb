# frozen_string_literal: true

module EE
  module Gitlab
    module Auth
      module Saml
        module Config
          extend ActiveSupport::Concern

          def auditor_groups
            options[:auditor_groups].is_a?(Array) ? options[:auditor_groups] : []
          end

          def required_groups
            Array(options[:required_groups])
          end

          def group_sync_enabled?
            self.class.enabled? && groups.present? && ::License.feature_available?(:saml_group_sync)
          end

          # This method is specific to a given provider.
          # Ensures provider is configured to look for groups in the SAML response.
          def microsoft_group_sync_enabled?
            self.class.microsoft_group_sync_enabled? && groups.present?
          end

          class_methods do
            # This method is not provider-specific.
            # Ensure at least one SAML provider is enabled and feature is licensed
            def microsoft_group_sync_enabled?
              ::Feature.enabled?(:microsoft_azure_group_sync) &&
                enabled? && ::License.feature_available?(:microsoft_group_sync)
            end
          end
        end
      end
    end
  end
end
