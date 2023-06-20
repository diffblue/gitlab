# frozen_string_literal: true

module AuditEvents
  module Streaming
    module InstanceHeaders
      class DestroyService < BaseService
        def execute
          _, response = destroy_header(params[:header])
          response
        end
      end
    end
  end
end
