# frozen_string_literal: true

module API
  module Entities
    module MergeRequests
      class StatusCheck < Grape::Entity
        expose :id
        expose :name
        expose :external_url
        expose :status

        def status
          if ::Feature.enabled?(:status_checks_add_status_field, object.project, default_enabled: :yaml)
            object.status(options[:merge_request], options[:sha])
          else
            object.approved?(options[:merge_request], options[:sha]) ? 'approved' : 'pending'
          end
        end
      end
    end
  end
end
