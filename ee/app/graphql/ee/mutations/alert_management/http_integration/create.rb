# frozen_string_literal: true

module EE
  module Mutations
    module AlertManagement
      module HttpIntegration
        module Create
          extend ActiveSupport::Concern

          prepended do
            argument :payload_example, ::Types::JsonStringType,
                     required: false,
                     description: 'Example of an alert payload.'

            argument :payload_attribute_mappings, [::Types::AlertManagement::PayloadAlertFieldInputType],
                     required: false,
                     description: 'Custom mapping of GitLab alert attributes to fields from the payload example.'
          end
        end
      end
    end
  end
end
