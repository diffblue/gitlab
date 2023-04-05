# frozen_string_literal: true

module API
  module Entities
    module Namespaces
      module Storage
        class LimitExclusion < Grape::Entity
          expose :id, documentation: { type: 'integer', example: 1 }
          expose :namespace_id, documentation: { type: 'integer', example: 123 }
          expose :namespace_name, documentation: { type: 'string', example: 'GitLab' }
          expose :reason, documentation: { type: 'string', example: 'a reason' }

          private

          def namespace_name
            object.namespace.name
          end
        end
      end
    end
  end
end
