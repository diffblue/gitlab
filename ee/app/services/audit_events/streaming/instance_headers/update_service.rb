# frozen_string_literal: true

module AuditEvents
  module Streaming
    module InstanceHeaders
      class UpdateService < BaseService
        def execute
          _, response = update_header(params[:header], params[:key], params[:value])
          response
        end
      end
    end
  end
end
