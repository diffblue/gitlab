# frozen_string_literal: true
module AuditEvents
  module Streaming
    module Headers
      class Base < ::BaseGroupService
        attr_reader :destination

        def execute
          @destination = params[:destination]
          return destination_error if @destination.blank?

          unless feature_enabled?
            raise Gitlab::Graphql::Errors::ResourceNotAvailable, 'feature disabled'
          end
        end

        private

        def destination_error
          ServiceResponse.error(message: "missing destination param")
        end

        def feature_enabled?
          Feature.enabled?(:streaming_audit_event_headers, group)
        end

      end
    end
  end
end
