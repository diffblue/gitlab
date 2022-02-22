# frozen_string_literal: true

module EE
  module Types
    module Projects
      module ServiceTypeEnum
        extend ActiveSupport::Concern

        class_methods do
          extend ::Gitlab::Utils::Override

          private

          override :type_description
          def type_description(name, type)
            description = super
            description = [description, ' (Gitlab.com only)'].join if saas_only?(name)
            description
          end

          def saas_only?(name)
            ::Integration.saas_only_integration_names.include?(name)
          end
        end
      end
    end
  end
end
