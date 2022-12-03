# frozen_string_literal: true

module Analytics
  module DevopsAdoption
    module EnabledNamespaces
      class BulkFindOrCreateService
        def initialize(current_user:, params: {})
          @params = params
          @current_user = current_user
        end

        def execute
          authorize!

          enabled_namespaces = services.map do |service|
            service.execute.payload[:enabled_namespace]
          end

          ServiceResponse.success(payload: { enabled_namespaces: enabled_namespaces })
        end

        def authorize!
          services.each(&:authorize!)
        end

        private

        attr_reader :params, :current_user

        def services
          @services ||= params[:namespaces].map do |namespace|
            FindOrCreateService.new(current_user: current_user,
                                    params: { namespace: namespace, display_namespace: params[:display_namespace] })
          end
        end
      end
    end
  end
end
