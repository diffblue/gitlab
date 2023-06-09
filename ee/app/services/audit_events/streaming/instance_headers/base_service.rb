# frozen_string_literal: true

module AuditEvents
  module Streaming
    module InstanceHeaders
      class BaseService
        include AuditEvents::Streaming::HeadersOperations

        attr_reader :params

        def initialize(params: {})
          @params = params
        end
      end
    end
  end
end
