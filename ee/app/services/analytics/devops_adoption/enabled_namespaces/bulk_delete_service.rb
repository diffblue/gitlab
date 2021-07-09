# frozen_string_literal: true

module Analytics
  module DevopsAdoption
    module EnabledNamespaces
      class BulkDeleteService
        def initialize(enabled_namespaces:, current_user:)
          @enabled_namespaces = enabled_namespaces
          @current_user = current_user
        end

        def execute
          deletion_services.map(&:authorize!)

          result = nil

          ApplicationRecord.transaction do
            deletion_services.each do |service|
              response = service.execute

              if response.error?
                result = ServiceResponse.error(message: response.message, payload: response_payload)
                raise ActiveRecord::Rollback
              end
            end

            result = ServiceResponse.success(payload: response_payload)
          end

          result
        end

        private

        attr_reader :enabled_namespaces, :current_user

        def response_payload
          { enabled_namespaces: enabled_namespaces }
        end

        def deletion_services
          @deletion_services ||= enabled_namespaces.map do |ns|
            DeleteService.new(current_user: current_user, enabled_namespace: ns)
          end
        end
      end
    end
  end
end
