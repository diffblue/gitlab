# frozen_string_literal: true

module AuditEvents
  module Streaming
    module InstanceHeaders
      class DestroyService < BaseService
        def execute
          destroy_header(params[:header])
        end
      end
    end
  end
end
