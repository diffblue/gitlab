# frozen_string_literal: true

module AuditEvents
  module Streaming
    module Headers
      class CreateService < Base
        def execute
          super
          create_header(destination, params[:key], params[:value])
        end
      end
    end
  end
end
