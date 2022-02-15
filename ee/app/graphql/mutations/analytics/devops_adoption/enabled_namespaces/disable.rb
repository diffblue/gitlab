# frozen_string_literal: true

module Mutations
  module Analytics
    module DevopsAdoption
      module EnabledNamespaces
        class Disable < BaseMutation
          graphql_name 'DisableDevopsAdoptionNamespace'
          description '**BETA** This endpoint is subject to change without notice.'

          include Mixins::CommonMethods

          argument :id, [::Types::GlobalIDType[::Analytics::DevopsAdoption::EnabledNamespace]],
                   required: true,
                   description: 'One or many IDs of the enabled namespaces to disable.'

          def resolve(id:, **)
            enabled_namespaces = GlobalID::Locator.locate_many(id)

            with_authorization_handler do
              service = ::Analytics::DevopsAdoption::EnabledNamespaces::BulkDeleteService
                .new(enabled_namespaces: enabled_namespaces, current_user: current_user)

              response = service.execute

              errors = response.payload[:enabled_namespaces].sum { |ns| errors_on_object(ns) }

              { errors: errors }
            end
          end
        end
      end
    end
  end
end
