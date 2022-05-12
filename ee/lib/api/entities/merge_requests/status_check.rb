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
          object.status(options[:merge_request], options[:sha])
        end
      end
    end
  end
end
