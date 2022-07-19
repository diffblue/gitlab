# frozen_string_literal: true
module AuditEvents
  module Streaming
    module Headers
      class CreateService < Base
        def execute
          super

          header = destination.headers.new(key: params[:key], value: params[:value])

          if header.save
            ServiceResponse.success(payload: { header: header, errors: [] })
          else
            ServiceResponse.error(message: Array(header.errors))
          end
        end
      end
    end
  end
end
