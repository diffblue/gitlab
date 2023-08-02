# frozen_string_literal: true

module AuditEvents
  module Streaming
    module InstanceHeaders
      class UpdateService < BaseService
        def execute
          update_header(params[:header], params[:key], params[:value])
        end
      end
    end
  end
end
