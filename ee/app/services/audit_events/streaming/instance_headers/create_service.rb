# frozen_string_literal: true

module AuditEvents
  module Streaming
    module InstanceHeaders
      class CreateService < BaseService
        def execute
          _, response, _ = create_header(params[:destination], params[:key], params[:value])
          response
        end
      end
    end
  end
end
