# frozen_string_literal: true

module EE
  module API
    module Entities
      class MemberRole < Grape::Entity
        expose :id, documentation: { type: 'integer', example: 2 }
        expose :namespace_id, as: :group_id, documentation: { type: 'integer', example: 2 }
        expose :name, documentation: { type: 'text', example: 'Custom guest' }
        expose :description, documentation: { type: 'text', example: 'Guest user who can also read_code' }
        expose :base_access_level, documentation: {
          type: 'integer',
          example: 40,
          description: "Access level. Valid values #{::MemberRole.levels_sentence}.",
          values: ::MemberRole::LEVELS
        }

        ::MemberRole::ALL_CUSTOMIZABLE_PERMISSIONS.each_key do |permission_name|
          expose permission_name, documentation: { type: 'boolean' }
        end
      end
    end
  end
end
