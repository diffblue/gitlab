# frozen_string_literal: true

module QA
  module EE
    module Resource
      # Provides access to the AuditEvents API
      # See: https://docs.gitlab.com/ee/api/audit_events.html
      class AuditEvents < QA::Resource::Base
        class << self
          # All audit events
          #
          # @param [QA::Runtime::API::Client] api_client
          # @param [Hash] **kwargs query arguments
          # @return [Array]
          def all(api_client = nil, **kwargs)
            instance(api_client).all(**kwargs)
          end

          private

          # An instance of the AuditEvents Resource
          #
          # @return [QA::EE::Resource::AuditEvents]
          def instance(api_client)
            init { |resource| resource.api_client = api_client || QA::Runtime::API::Client.as_admin }
          end
        end

        # All audit events
        #
        # @param [Hash] **kwargs query arguments
        # @return [Array]
        def all(**kwargs)
          auto_paginated_response(request_url(api_get_path, per_page: "100", **kwargs))
        end

        def fabricate_via_api!
          api_get
        end

        def api_get_path
          "/audit_events"
        end

        def api_support?
          # Overridden because this API only supports GET
          respond_to?(:api_get_path)
        end
      end
    end
  end
end
