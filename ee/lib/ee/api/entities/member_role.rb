# frozen_string_literal: true

module EE
  module API
    module Entities
      class MemberRole < Grape::Entity
        expose :id, documentation: { type: 'integer', example: 2 }
        expose :namespace_id, as: :group_id, documentation: { type: 'integer', example: 2 }
        expose :base_access_level,
          documentation: { type: 'integer',
                           example: 40,
                           description: 'Access level. Valid values are 10 (Guest), 20 (Reporter), 30 (Developer) \
      , 40 (Maintainer), and 50 (Owner).',
                           values: [10, 20, 30, 40, 50] }
        expose :read_code, documentation: { type: 'boolean' }
      end
    end
  end
end
