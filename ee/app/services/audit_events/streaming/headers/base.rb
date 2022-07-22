# frozen_string_literal: true
module AuditEvents
  module Streaming
    module Headers
      class Base < ::BaseGroupService
        attr_reader :destination

        def initialize(destination:, current_user: nil, params: {})
          @destination = destination

          super(
            group: @destination&.group,
            current_user: current_user,
            params: params
          )
        end

        def execute
          return destination_error if destination.blank?
        end

        private

        def destination_error
          ServiceResponse.error(message: "missing destination param")
        end
      end
    end
  end
end
