# frozen_string_literal: true

module EE
  module API
    module Entities
      module Ci
        module Minutes
          class AdditionalPack < Grape::Entity
            expose :namespace_id, documentation: { type: 'string', example: 123 }
            expose :expires_at, documentation: { type: 'date', example: '2012-05-28' }
            expose :number_of_minutes, documentation: { type: 'integer', example: 10000 }
            expose :purchase_xid, documentation: { type: 'string', example: '46952fe69bebc1a4de10b2b4ff439d0c' }
          end
        end
      end
    end
  end
end
