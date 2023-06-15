# frozen_string_literal: true

module EE
  module API
    module Entities
      module GitlabSubscriptions
        class AddOnPurchase < Grape::Entity
          expose :namespace_id, documentation: { type: 'integer', example: 123 }
          expose :namespace_name, documentation: { type: 'string', example: 'GitLab' }
          expose :add_on, documentation: { type: 'string', example: 'Code Suggestions' }
          expose :quantity, documentation: { type: 'integer', example: 10 }
          expose :expires_on, documentation: { type: 'date', example: '2023-05-30' }
          expose :purchase_xid, documentation: { type: 'string', example: 'A-S00000001' }

          def namespace_name
            object.namespace.name
          end

          def add_on
            object.add_on.name.titleize
          end
        end
      end
    end
  end
end
