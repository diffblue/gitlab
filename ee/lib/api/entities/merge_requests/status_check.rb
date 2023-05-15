# frozen_string_literal: true

module API
  module Entities
    module MergeRequests
      class StatusCheck < Grape::Entity
        expose :id, documentation: { type: 'integer', example: 1 }
        expose :name, documentation: { type: 'string', example: 'QA' }
        expose :external_url, documentation: { type: 'string', example: 'https://www.example.com' }
        expose :status, documentation: { type: 'string', example: 'passed' }

        def status
          object.status(options[:merge_request], options[:sha])
        end

        def external_url
          if options[:current_user].can?(:developer_access, options[:merge_request].project)
            return object.external_url[/[^?]+/]
          end

          ''
        end
      end
    end
  end
end
